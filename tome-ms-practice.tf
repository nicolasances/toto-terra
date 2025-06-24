# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "tome-ms-practice-service-account" {
  account_id = "tome-ms-practice"
  display_name = "Tome Practice Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "tome-ms-practice-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.tome-ms-practice-service-account.email)
}
resource "google_project_iam_member" "tome-ms-practice-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.tome-ms-practice-service-account.email)
}
resource "google_project_iam_member" "tome-ms-practice-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.tome-ms-practice-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "tome-ms-practice-registry" {
    location = var.gcp_region
    repository_id = "tome-ms-practice"
    format = "DOCKER"
    description = "Toto MS Practice Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "tome-ms-practice-github-environment" {
    repository = "tome-ms-practice"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-practice-bucket-envsecret" {
    repository = "tome-ms-practice"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "tome-ms-practice-secret-cicdsakey" {
    repository = "tome-ms-practice"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "tome-ms-practice-var-pid" {
    repository = "tome-ms-practice"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-practice-secret-service-account" {
    repository = "tome-ms-practice"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.tome-ms-practice-service-account.email
}
resource "github_actions_environment_variable" "tome_ms_practice_github_envvar_flashcards_endpoint" {
    repository = "tome"
    environment = var.toto_environment
    variable_name = "TOME_FLASHCARDS_API_ENDPOINT"
    value = format("https://tome-ms-flashcards-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_variable" "tome_ms_practice_github_envvar_flashcards_endpoint" {
    repository = "tome"
    environment = var.toto_environment
    variable_name = "TOME_TOPICS_API_ENDPOINT"
    value = format("https://tome-ms-topics-%s", var.cloud_run_endpoint_suffix)
}


# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "tome_ms_practice_mongo_user" {
    description = "Mongo User for tome practice"
    type = string
    sensitive = true
}
variable "tome_ms_practice_mongo_pswd" {
    description = "Mongo Password for tome practice"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "tome-ms-practice-mongo-user" {
    secret_id = "tome-ms-practice-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-practice-mongo-user-version" {
    secret = google_secret_manager_secret.tome-ms-practice-mongo-user.id
    secret_data = var.tome_ms_practice_mongo_user
}
resource "google_secret_manager_secret" "tome-ms-practice-mongo-pswd" {
    secret_id = "tome-ms-practice-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-practice-mongo-pswd-version" {
    secret = google_secret_manager_secret.tome-ms-practice-mongo-pswd.id
    secret_data = var.tome_ms_practice_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------