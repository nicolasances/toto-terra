# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "tome-ms-topics-service-account" {
  account_id = "tome-ms-topics"
  display_name = "Tome Topics API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "tome-ms-topics-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}
resource "google_project_iam_member" "tome-ms-topics-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}
resource "google_project_iam_member" "tome-ms-topics-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "tome-ms-topics-github-environment" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-topics-bucket-envsecret" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "tome-ms-topics-secret-cicdsakey" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "tome-ms-topics-var-pid" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-topics-secret-service-account" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.tome-ms-topics-service-account.email
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "tome_ms_topics_mongo_user" {
    description = "Mongo User for Tome Topics API"
    type = string
    sensitive = true
}
variable "tome_ms_topics_mongo_pswd" {
    description = "Mongo Password for Tome Topics API"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "tome-ms-topics-mongo-user" {
    secret_id = "tome-ms-topics-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-topics-mongo-user-version" {
    secret = google_secret_manager_secret.tome-ms-topics-mongo-user.id
    secret_data = var.tome_ms_topics_mongo_user
}
resource "google_secret_manager_secret" "tome-ms-topics-mongo-pswd" {
    secret_id = "tome-ms-topics-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-topics-mongo-pswd-version" {
    secret = google_secret_manager_secret.tome-ms-topics-mongo-pswd.id
    secret_data = var.tome_ms_topics_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------