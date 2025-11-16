# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "gale_ui_service_account" {
  account_id = "gale-ui"
  display_name = "Gale UI Service Account"
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "gale-ui-webapp-registry" {
    location = var.gcp_region
    repository_id = "gale-ui"
    format = "DOCKER"
    description = "Gale UI Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment, secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "gale_ui_github_environment" {
    repository = "gale-ui"
    environment = var.toto_environment
}
resource "github_actions_environment_secret" "gale_ui_github_secret_auth_endpoint" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-auth-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "gale_ui_github_secret_aws_api_endpoint" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "AWS_TOTO_API_ENDPOINT"
    plaintext_value  = format("https://api.%s.toto.aws.to7o.com", var.toto_environment)
}
resource "github_actions_environment_secret" "gale_ui_github_secret_service_account" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.gale_ui_service_account.email
}
resource "github_actions_environment_secret" "gale_ui_github_secret_cicdsakey" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_secret" "gale_ui_github_secret_client_id" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "GOOGLE_CLIENT_ID"
    plaintext_value = var.web_google_client_id
}
resource "github_actions_environment_secret" "gale_ui_github_secret_gcppid" {
    repository = "gale-ui"
    environment = var.toto_environment
    secret_name = "GCP_PID"
    plaintext_value = var.gcp_pid
}
resource "github_actions_environment_variable" "gale_ui_github_envvar_tometopics_api_endpoint" {
    repository = "gale-ui"
    environment = var.toto_environment
    variable_name = "GALE_BROKER_API_ENDPOINT"
    value = format("https://api.%s.toto.nimoto.eu/galebroker", var.toto_aws_environment)
}