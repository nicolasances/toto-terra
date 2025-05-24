# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_actions_environment_secret" "web_expenses_github_secret_expenses_endpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "EXPENSESV2_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-expenses-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_expenses_github_secret_games_endpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "GAMES_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-games-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_expenses_github_secret_incast_endpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "INCAST_API_ENDPOINT"
    plaintext_value  = format("https://toto-ml-incast-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "totoreactjsexpenses-secret-cicdsakey" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}