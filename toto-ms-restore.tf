# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-restore-service-account" {
  account_id = "toto-ms-restore"
  display_name = "Restore Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-restore-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-restore-service-account.email)
}
resource "google_project_iam_member" "toto-ms-restore-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-restore-service-account.email)
}
resource "google_project_iam_member" "toto-ms-restore-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-restore-service-account.email)
}

# ---------------------------------------------------------------
# 2. Storage Bucket 
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-restore-github-environment" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsrestore-secret-cicdsakey" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomsrestore-var-pid" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsrestore-secret-service-account" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-restore-service-account.email
}
resource "github_actions_environment_secret" "secret_restore_kud_api_endpoint" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "KUD_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-kud-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "secret_restore_expensesv2_api_endpoint" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "EXPENSESV2_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-expenses-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "secret_restore_games_api_endpoint" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "GAMES_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-games-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "secret_restore_backup_bucket" {
    repository = "toto-ms-restore"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value = google_storage_bucket.backup-bucket.name
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "restore_allowed_user" {
    description = "User that is allowed to execute a restore"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto_restore_user_secret" {
    secret_id = "toto-restore-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto_restore_user_secret_version" {
    secret = google_secret_manager_secret.toto_restore_user_secret.id
    secret_data = var.restore_allowed_user
}
# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 7. Artifact Registry
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-restore-artifact-repo" {
    location = "europe-west1"
    repository_id = "toto-ms-restore"
    description = "Artifact Registry for toto-ms-restore"
    format = "DOCKER"
    
    docker_config {
        immutable_tags = true
    }

    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-minimum-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count            = 1
        }
    }
}