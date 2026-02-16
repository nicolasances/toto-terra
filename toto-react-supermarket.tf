# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "web_suppie_service_account" {
  account_id = "toto-suppie"
  display_name = "Toto Suppie Service Account"
}

# ---------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "web_suppie_registry" {
    location = var.gcp_region
    repository_id = "toto-suppie"
    format = "DOCKER"
    description = "Toto Suppie API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment, secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "web_suppie_github_environment" {
    repository = "toto-suppie"
    environment = var.toto_environment
}
resource "github_actions_environment_secret" "web_suppie_github_secret_expenses_endpoint" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "SUPERMARKET_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-supermarket-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_games_endpoint" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-auth-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_service_account" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.web_suppie_service_account.email
}
resource "github_actions_environment_secret" "web_suppie_github_secret_cicdsakey" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_secret" "web_suppie_github_secret_client_id" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "GOOGLE_CLIENT_ID"
    plaintext_value = var.web_google_client_id
}
resource "github_actions_environment_secret" "web_suppie_github_secret_gcppid" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "GCP_PID"
    plaintext_value = var.gcp_pid
}