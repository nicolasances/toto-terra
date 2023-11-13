# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_actions_environment_secret" "web_expenses_github_secret_expenses_endpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "EXPENSESV2_API_ENDPOINT"
    plaintext_value  = format("https://toto-ms-expenses-%s", var.cloud_run_endpoint_suffix)
}