# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "tome_service_account" {
  account_id = "toto-tome"
  display_name = "Tome Service Account"
}

# ---------------------------------------------------------------
# 3. Github environment, secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "tome_github_environment" {
    repository = "tome"
    environment = var.toto_environment
}
resource "github_actions_environment_secret" "tome_github_secret_auth_endpoint" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-auth-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "tome_github_secret_aws_api_endpoint" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "AWS_TOTO_API_ENDPOINT"
    plaintext_value  = format("https://api.%s.toto.aws.to7o.com", var.toto_environment)
}
resource "github_actions_environment_secret" "tome_github_secret_service_account" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.tome_service_account.email
}
resource "github_actions_environment_secret" "tome_github_secret_cicdsakey" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_secret" "tome_github_secret_client_id" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "GOOGLE_CLIENT_ID"
    plaintext_value = var.web_google_client_id
}
resource "github_actions_environment_secret" "tome_github_secret_gcppid" {
    repository = "tome"
    environment = var.toto_environment
    secret_name = "GCP_PID"
    plaintext_value = var.gcp_pid
}