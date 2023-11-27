# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-games-service-account" {
  account_id = "toto-ms-games"
  display_name = "Games Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-games-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-games-service-account.email)
}
resource "google_project_iam_member" "toto-ms-games-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-games-service-account.email)
}
resource "google_project_iam_member" "toto-ms-games-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-games-service-account.email)
}

# ---------------------------------------------------------------
# 2. Storage Bucket 
# ---------------------------------------------------------------
resource "google_storage_bucket" "games_data_bucket" {
    name = format("%s-games-data-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-games-github-environment" {
    repository = "toto-ms-games"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsgames-secret-cicdsakey" {
    repository = "toto-ms-games"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomsgames-var-pid" {
    repository = "toto-ms-games"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsgames-secret-service-account" {
    repository = "toto-ms-games"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-games-service-account.email
}
resource "github_actions_environment_secret" "toto_games_data_backup_github_env" {
    repository = "toto-ms-games"
    environment = var.gcp_pid
    secret_name = "GAMES_BUCKET"
    plaintext_value  = google_storage_bucket.games_data_bucket.name
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_games_mongo_user" {
    description = "Mongo User for games"
    type = string
    sensitive = true
}
variable "toto_ms_games_mongo_pswd" {
    description = "Mongo Password for games"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-games-mongo-user" {
    secret_id = "toto-ms-games-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-games-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-games-mongo-user.id
    secret_data = var.toto_ms_games_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-games-mongo-pswd" {
    secret_id = "toto-ms-games-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-games-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-games-mongo-pswd.id
    secret_data = var.toto_ms_games_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------