# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ml-expcat-service-account" {
  account_id = "toto-ml-expcat"
  display_name = "Expcat Model Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ml-expcat-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ml-expcat-service-account.email)
}
resource "google_project_iam_member" "toto-ml-expcat-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ml-expcat-service-account.email)
}
resource "google_project_iam_member" "toto-ml-expcat-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ml-expcat-service-account.email)
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ml-expcat-github-environment" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ml-expcat-secret-cicdsakey" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ml-expcat-var-pid" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ml-expcat-secret-service-account" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ml-expcat-service-account.email
}
resource "github_actions_environment_secret" "toto_kud_backup_bucket" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto_kud_backup_bucket" {
    repository = "toto-ml-expcat"
    environment = var.gcp_pid
    secret_name = "MODELS_BUCKET"
    plaintext_value  = google_storage_bucket.models-bucket.name
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