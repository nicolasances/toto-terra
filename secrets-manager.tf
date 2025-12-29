# ---------------------------------------------------------------
# 1. Variables for Secret Manager
# ---------------------------------------------------------------
variable "target_audience" {
    description = "Target Audience to use in JWT flows"
    type = string
    sensitive = true
}

# ---------------------------------------------------------------
# 2. Generic Secrets to be stored in Secrets Manager
# ---------------------------------------------------------------
resource "google_secret_manager_secret" "secret_target_audience" {
    secret_id = "toto-expected-audience"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_target_audience" {
    secret = google_secret_manager_secret.secret_target_audience.id
    secret_data = var.target_audience
}
resource "google_secret_manager_secret" "secret_toto_auth_endpoint" {
    secret_id = "toto-auth-endpoint"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_toto_auth_endpoint" {
    secret = google_secret_manager_secret.secret_toto_auth_endpoint.id
    secret_data = format("https://toto-ms-auth-%s", var.cloud_run_endpoint_suffix)
}

resource "google_secret_manager_secret" "secret_aws_sandbox_llm_api_endpoint" {
    secret_id = "aws-sandbox-llm-api-endpoint"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_aws_sandbox_llm_api_endpoint" {
    secret = google_secret_manager_secret.secret_aws_sandbox_llm_api_endpoint.id
    secret_data = var.aws_sandbox_llm_api
}

resource "google_secret_manager_secret" "secret_toto_registry_endpoint" {
    secret_id = "toto-registry-endpoint"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_toto_registry_endpoint" {
    secret = google_secret_manager_secret.secret_toto_registry_endpoint.id
    secret_data = var.toto_registry_endpoint
}