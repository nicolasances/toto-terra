# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-expenses-service-account" {
  account_id = "toto-ms-expenses"
  display_name = "Expenses Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-expenses-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}
resource "google_project_iam_member" "toto-ms-expenses-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}
resource "google_project_iam_member" "toto-ms-expenses-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}

# ---------------------------------------------------------------
# 2. Artifact Repository
# The repository already exists: it is imported, not recreated
# ---------------------------------------------------------------
import {
    to = google_artifact_registry_repository.toto-ms-expenses-registry
    id = format("projects/%s/locations/%s/repositories/toto-ms-expenses", var.gcp_pid, var.gcp_region)
}
resource "google_artifact_registry_repository" "toto-ms-expenses-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-expenses"
    format = "DOCKER"
    description = "Toto MS Expenses Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-recent-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count = 10
        }
    }

    cleanup_policies {
        id     = "delete-old"
        action = "DELETE"
        condition {
            tag_state  = "ANY"
            older_than = "604800s"  # 7 days
        }
    }
}

# Allow the GKE nodes (toto-terra-gke, other GCP project) to pull images from this registry
resource "google_artifact_registry_repository_iam_member" "toto-ms-expenses-gke-reader" {
  project    = google_artifact_registry_repository.toto-ms-expenses-registry.project
  location   = google_artifact_registry_repository.toto-ms-expenses-registry.location
  repository = google_artifact_registry_repository.toto-ms-expenses-registry.name
  role       = "roles/artifactregistry.reader"
  member     = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-expenses-github-environment" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto_backup_bucket_envsecret" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "totomsexpenses-secret-cicdsakey" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomsexpenses-var-pid" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsexpenses-secret-service-account" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-expenses-service-account.email
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_expenses_mongo_user" {
    description = "Mongo User for expenses"
    type = string
    sensitive = true
}
variable "toto_ms_expenses_mongo_pswd" {
    description = "Mongo Password for expenses"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-expenses-mongo-user" {
    secret_id = "toto-ms-expenses-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-expenses-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-expenses-mongo-user.id
    secret_data = var.toto_ms_expenses_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-expenses-mongo-pswd" {
    secret_id = "toto-ms-expenses-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-expenses-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-expenses-mongo-pswd.id
    secret_data = var.toto_ms_expenses_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
resource "google_dns_record_set" "api_expenses_dns" {
  name = format("expenses.api.%s.toto.nimatz.com.", var.toto_environment)
  rrdatas = ["ghs.googlehosted.com."]
  type = "CNAME"
  ttl  = 3600
  managed_zone = google_dns_managed_zone.dns_zone.name
  project = var.gcp_pid
}
# 5.2. Domain Mapping
resource "google_cloud_run_domain_mapping" "api_expenses_domain_mapping" {
  location = var.gcp_region
  name = format("expenses.api.%s.toto.nimatz.com", var.toto_environment)
  spec {
    route_name = "toto-ms-expenses"
  }
  metadata {
    namespace = var.gcp_pid
  }
}


# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
resource "google_pubsub_subscription" "sub_expenses_self" {
    name = "ExpensesEventsToSelf"
    topic = google_pubsub_topic.topic_expenses.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://toto-ms-expenses-%s/expenses/events", var.cloud_run_endpoint_suffix)
      oidc_token {
        service_account_email = google_service_account.toto-pubsub-service-account.email
        audience = var.target_audience
      }
    }

    expiration_policy {
      ttl = ""
    }

    retry_policy {
      minimum_backoff = "10s"
      maximum_backoff = "600s"
    }
}
resource "google_pubsub_subscription" "sub_tags_self" {
    name = "TagEventsToSelf"
    topic = google_pubsub_topic.topic_tags.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://toto-ms-expenses-%s/expenses/events", var.cloud_run_endpoint_suffix)
      oidc_token {
        service_account_email = google_service_account.toto-pubsub-service-account.email
        audience = var.target_audience
      }
    }

    expiration_policy {
      ttl = ""
    }

    retry_policy {
      minimum_backoff = "10s"
      maximum_backoff = "600s"
    }
}

# ---------------------------------------------------------------
# 7. GKE Cluster authorization
# Use this when hosting this microservice in a GKE cluster in another GCP project, to access the toto GCP projects (dev and prod)
# ---------------------------------------------------------------
locals {
    toto_ms_expenses_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/toto-ms-expenses",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
resource "google_project_iam_member" "toto-ms-expenses-gke-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = local.toto_ms_expenses_gke_principal
}
# Scoped to the backup bucket only (the Cloud Run service account has the project-wide storage.admin)
resource "google_storage_bucket_iam_member" "toto-ms-expenses-gke-role-backup-bucket" {
    bucket = google_storage_bucket.backup-bucket.name
    role = "roles/storage.objectAdmin"
    member = local.toto_ms_expenses_gke_principal
}
resource "google_project_iam_member" "toto-ms-expenses-gke-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = local.toto_ms_expenses_gke_principal
}
