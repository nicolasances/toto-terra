# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-kud-service-account" {
  account_id = "toto-ms-kud"
  display_name = "Kud Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-kud-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-kud-service-account.email)
}
resource "google_project_iam_member" "toto-ms-kud-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-kud-service-account.email)
}
resource "google_project_iam_member" "toto-ms-kud-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-kud-service-account.email)
}

# ---------------------------------------------------------------
# 2. Storage Bucket 
# ---------------------------------------------------------------
resource "google_storage_bucket" "kud_data_bucket" {
    name = format("%s-kud-data-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-kud-github-environment" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "totomskud-secret-cicdsakey" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomskud-var-pid" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomskud-secret-service-account" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-kud-service-account.email
}
resource "github_actions_environment_secret" "toto_kud_data_backup_github_env" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
    secret_name = "KUD_BUCKET"
    plaintext_value  = google_storage_bucket.kud_data_bucket.name
}
resource "github_actions_environment_secret" "toto_kud_backup_bucket" {
    repository = "toto-ms-kud"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_kud_mongo_user" {
    description = "Mongo User for kud"
    type = string
    sensitive = true
}
variable "toto_ms_kud_mongo_pswd" {
    description = "Mongo Password for kud"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-kud-mongo-user" {
    secret_id = "toto-ms-kud-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-kud-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-kud-mongo-user.id
    secret_data = var.toto_ms_kud_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-kud-mongo-pswd" {
    secret_id = "toto-ms-kud-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-kud-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-kud-mongo-pswd.id
    secret_data = var.toto_ms_kud_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
resource "google_pubsub_subscription" "sub_games_kud" {
    name = "GamesEventsToKud"
    topic = google_pubsub_topic.topic_games.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://toto-ms-kud-%s/events/games", var.cloud_run_endpoint_suffix)
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