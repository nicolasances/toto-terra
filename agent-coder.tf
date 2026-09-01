# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "agent_coder_service_account" {
  account_id = "agent-coder"
  display_name = "Agent Coder Service Account"
}
resource "google_service_account_key" "agent-coder-sa-key" {
    service_account_id = google_service_account.agent_coder_service_account.name
    private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "agent_coder_role_secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.agent_coder_service_account.email)
}
resource "google_project_iam_member" "agent_coder_role_gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.agent_coder_service_account.email)
}
resource "google_project_iam_member" "agent_coder_role_pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.agent_coder_service_account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "agent_coder_registry" {
    location = var.gcp_region
    repository_id = "agent-coder"
    format = "DOCKER"
    description = "Agent Coder Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "agent_coder-github-environment" {
    repository = "agent-coder"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "agent_coder-secret-cicdsakey" {
    repository = "agent-coder"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.agent-coder-sa-key.private_key)))
}