# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account
# ---------------------------------------------------------------
resource "google_service_account" "whispering-service-account" {
  account_id   = "whispering"
  display_name = "Whispering Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "whispering-role-secretmanagedaccessor" {
  project = var.gcp_pid
  role    = "roles/secretmanager.secretAccessor"
  member  = format("serviceAccount:%s", google_service_account.whispering-service-account.email)
}

# ---------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "whispering-registry" {
  location      = var.gcp_region
  repository_id = "whispering"
  format        = "DOCKER"
  description   = "Whispering Artifact Registry"
  labels = {
    "created_by" = "terraform"
    "project"    = var.gcp_pid
  }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "whispering-github-environment" {
  repository  = "whispering"
  environment = var.gcp_pid
}
resource "github_actions_environment_secret" "whispering-secret-cicdsakey" {
  repository      = "whispering"
  environment     = var.gcp_pid
  secret_name     = "CICD_SERVICE_ACCOUNT"
  plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_secret" "whispering-secret-service-account" {
  repository      = "whispering"
  environment     = var.gcp_pid
  secret_name     = "SERVICE_ACCOUNT"
  plaintext_value = google_service_account.whispering-service-account.email
}
resource "github_actions_environment_secret" "whispering-secret-backup-bucket" {
  repository      = "whispering"
  environment     = var.gcp_pid
  secret_name     = "BACKUP_BUCKET"
  plaintext_value = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_variable" "whispering-var-pid" {
  repository    = "whispering"
  environment   = var.gcp_pid
  variable_name = "GCP_PID"
  value         = var.gcp_pid
}
resource "github_actions_environment_variable" "whispering-var-region" {
  repository    = "whispering"
  environment   = var.gcp_pid
  variable_name = "GCP_REGION"
  value         = var.gcp_region
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
