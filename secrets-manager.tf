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
    secret_data = format("https://toto-ms-registry-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 3. Agent harness secrets & related
# ---------------------------------------------------------------
variable "claude_token" {
    description = "Claude Auth Token"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "secret_claude_token" {
    secret_id = "claude-token"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_claude_token" {
    secret = google_secret_manager_secret.secret_claude_token.id
    secret_data = var.claude_token
}

variable "coding_agent_gh_token" {
    description = "GitHub Token for Coding Agents"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "secret_coding_agent_gh_token" {
    secret_id = "coding-agent-gh-token"
    replication {
      auto {}
    }
}
resource "google_secret_manager_secret_version" "secret_version_coding_agent_gh_token" {
    secret = google_secret_manager_secret.secret_coding_agent_gh_token.id
    secret_data = var.coding_agent_gh_token
}