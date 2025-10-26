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
resource "google_service_account" "toto-ms-ex1-service-account" {
  account_id = "toto-ms-ex1"
  display_name = "Toto MS EX1 Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-ex1-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-ex1-service-account.email)
}
resource "google_project_iam_member" "toto-ms-ex1-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-ex1-service-account.email)
}
resource "google_project_iam_member" "toto-ms-ex1-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-ex1-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-ex1-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-ex1"
    format = "DOCKER"
    description = "Toto MS ex1 Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-ex1-github-environment" {
    repository = "toto-ms-ex1"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-ex1-bucket-envsecret" {
    repository = "toto-ms-ex1"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto-ms-ex1-secret-cicdsakey" {
    repository = "toto-ms-ex1"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-ex1-var-pid" {
    repository = "toto-ms-ex1"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-ex1-secret-service-account" {
    repository = "toto-ms-ex1"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-ex1-service-account.email
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------