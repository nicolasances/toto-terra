# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "web_suppie_service_account" {
  account_id = "toto-react-supermarket"
  display_name = "Toto Suppie Service Account"
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_actions_environment_secret" "web_suppie_github_secret_expenses_endpoint" {
    repository = "toto-react-supermarket"
    environment = var.toto_environment
    secret_name = "SUPERMARKET_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-supermarket-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_games_endpoint" {
    repository = "toto-react-supermarket"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-auth-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_service_account" {
    repository = "toto-react-supermarket"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.web_suppie_service_account.email
}
resource "github_actions_environment_secret" "web_suppie_github_secret_cicdsakey" {
    repository = "toto-react-supermarket"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_secret" "web_suppie_github_secret_client_id" {
    repository = "toto-react-supermarket"
    environment = var.gcp_pid
    secret_name = "GOOGLE_CLIENT_ID"
    plaintext_value = var.web_google_client_id
}