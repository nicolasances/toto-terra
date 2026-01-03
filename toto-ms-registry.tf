# ###############################################################
# ###############################################################
# YOU CAN DELETE THIS FILE AFTER RUNNING TERRAFORM
# ###############################################################
# ###############################################################
# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-registry-service-account" {
  account_id = "toto-ms-registry"
  display_name = "XXX Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-registry-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-registry-service-account.email)
}
resource "google_project_iam_member" "toto-ms-registry-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-registry-service-account.email)
}
resource "google_project_iam_member" "toto-ms-registry-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-registry-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-registry-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-registry"
    format = "DOCKER"
    description = "Toto MS XXX Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-registry-github-environment" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-registry-bucket-envsecret" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto-ms-registry-secret-cicdsakey" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-registry-var-pid" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-registry-secret-service-account" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-registry-service-account.email
}
resource "github_actions_environment_secret" "toto-ms-registry-secret-service-base-url" {
    repository = "toto-ms-registry"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://toto-ms-registry-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_ms_registry_mongo_user" {
    description = "Mongo User for xxx"
    type = string
    sensitive = true
}
variable "toto_ms_registry_mongo_pswd" {
    description = "Mongo Password for xxx"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-registry-mongo-user" {
    secret_id = "toto-ms-registry-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-registry-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-registry-mongo-user.id
    secret_data = var.toto_ms_registry_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-registry-mongo-pswd" {
    secret_id = "toto-ms-registry-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-registry-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-registry-mongo-pswd.id
    secret_data = var.toto_ms_registry_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------