# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-supermarket-service-account" {
  account_id = "toto-ms-supermarket"
  display_name = "XXX Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-supermarket-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-supermarket-service-account.email)
}
resource "google_project_iam_member" "toto-ms-supermarket-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-supermarket-service-account.email)
}
resource "google_project_iam_member" "toto-ms-supermarket-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-supermarket-service-account.email)
}
resource "google_project_iam_member" "toto-ms-supermarket_role_aiplatform" {
    project = var.gcp_pid
    role = "roles/aiplatform.user"
    member = format("serviceAccount:%s", google_service_account.toto-ms-supermarket-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-supermarket-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-supermarket"
    format = "DOCKER"
    description = "Toto MS Supermarket Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-minimum-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count = 1
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
resource "google_artifact_registry_repository_iam_member" "toto-ms-supermarket-gke-reader" {
  project    = google_artifact_registry_repository.toto-ms-supermarket-registry.project
  location   = google_artifact_registry_repository.toto-ms-supermarket-registry.location
  repository = google_artifact_registry_repository.toto-ms-supermarket-registry.name
  role       = "roles/artifactregistry.reader"
  member     = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-supermarket-github-environment" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-supermarket-bucket-envsecret" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.supermarket-backup-bucket.name
}
resource "github_actions_environment_secret" "toto-ms-supermarket-secret-cicdsakey" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-supermarket-var-pid" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-supermarket-secret-service-account" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-supermarket-service-account.email
}
resource "github_actions_environment_secret" "toto-ms-supermarket-secret-supito-endpoint" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "SUPITO_API_ENDPOINT"
    plaintext_value = format("https://api.%s.toto.aws.to7o.com", var.toto_environment)
}
resource "github_actions_environment_secret" "toto-ms-supermarket-secret-gale-broker-endpoint" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "GALE_BROKER_URL"
    plaintext_value = format("https://gale-broker-%s/galebroker", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "toto-ms-supermarket-secret-service-base-url" {
    repository = "toto-ms-supermarket"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://toto-ms-supermarket-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_supermarket_mongo_user" {
    description = "Mongo User for supermarket"
    type = string
    sensitive = true
}
variable "toto_ms_supermarket_mongo_pswd" {
    description = "Mongo Password for supermarket"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-supermarket-mongo-user" {
    secret_id = "toto-ms-supermarket-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-supermarket-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-supermarket-mongo-user.id
    secret_data = var.toto_ms_supermarket_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-supermarket-mongo-pswd" {
    secret_id = "toto-ms-supermarket-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-supermarket-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-supermarket-mongo-pswd.id
    secret_data = var.toto_ms_supermarket_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
resource "google_pubsub_subscription" "sub_supermarket_self" {
    name = "SupermarketEventToSelf"
    topic = google_pubsub_topic.topic_supermarket.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://toto-ms-supermarket-%s/events", var.cloud_run_endpoint_suffix)
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
    toto_ms_supermarket_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/toto-ms-supermarket",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
resource "google_project_iam_member" "toto-ms-supermarket-gke-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = local.toto_ms_supermarket_gke_principal
}
resource "google_project_iam_member" "toto-ms-supermarket-gke-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = local.toto_ms_supermarket_gke_principal
}
resource "google_project_iam_member" "toto-ms-supermarket-gke-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = local.toto_ms_supermarket_gke_principal
}
resource "google_project_iam_member" "toto-ms-supermarket-gke-role-aiplatform" {
    project = var.gcp_pid
    role = "roles/aiplatform.user"
    member = local.toto_ms_supermarket_gke_principal
}
