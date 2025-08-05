# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-llm-service-account" {
  account_id = "toto-ms-llm"
  display_name = "Toto LLM Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-llm-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-llm-service-account.email)
}
resource "google_project_iam_member" "toto-ms-llm-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-llm-service-account.email)
}
resource "google_project_iam_member" "toto-ms-llm-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-llm-service-account.email)
}
resource "google_project_iam_member" "toto-ms-llm-role-genai" {
    project = var.gcp_pid
    role = "roles/aiplatform.user"
    member = format("serviceAccount:%s", google_service_account.toto-ms-llm-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-llm-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-llm"
    format = "DOCKER"
    description = "Toto MS LLM Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-llm-github-environment" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-llm-bucket-envsecret" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto-ms-llm-secret-cicdsakey" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-llm-var-pid" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_variable" "toto-ms-llm-var-region" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
    variable_name = "GCP_REGION"
    value = var.gcp_region
}
resource "github_actions_environment_secret" "toto-ms-llm-secret-service-account" {
    repository = "toto-ms-llm"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-llm-service-account.email
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_llm_mongo_user" {
    description = "Mongo User for Toto LLM"
    type = string
    sensitive = true
}
variable "toto_ms_llm_mongo_pswd" {
    description = "Mongo Password for Toto LLM"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-llm-mongo-user" {
    secret_id = "toto-ms-llm-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-llm-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-llm-mongo-user.id
    secret_data = var.toto_ms_llm_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-llm-mongo-pswd" {
    secret_id = "toto-ms-llm-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-llm-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-llm-mongo-pswd.id
    secret_data = var.toto_ms_llm_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------