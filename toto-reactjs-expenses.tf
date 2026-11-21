# ---------------------------------------------------------------
# 2. Artifact Repository
# The repository already exists: it is imported, not recreated
# ---------------------------------------------------------------
import {
    to = google_artifact_registry_repository.toto-reactjs-expenses-registry
    id = format("projects/%s/locations/%s/repositories/toto-reactjs-expenses", var.gcp_pid, var.gcp_region)
}
resource "google_artifact_registry_repository" "toto-reactjs-expenses-registry" {
    location = var.gcp_region
    repository_id = "toto-reactjs-expenses"
    format = "DOCKER"
    description = "Toto Expenses Web App Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    # KEEP takes precedence over DELETE: the 10 most recent versions are never deleted,
    # so the image running on GKE (deployed by CI) and a few rollback targets always stay available.
    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-recent-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count = 10
        }
    }

    cleanup_policies {
        id     = "delete-old"
        action = "DELETE"
        condition {
            tag_state  = "ANY"
            older_than = "604800s"  # 7 days
        }
    }
}

# Allow the GKE nodes (toto-terra-gke, other GCP project) to pull images from this registry
resource "google_artifact_registry_repository_iam_member" "toto-reactjs-expenses-gke-reader" {
  project    = google_artifact_registry_repository.toto-reactjs-expenses-registry.project
  location   = google_artifact_registry_repository.toto-reactjs-expenses-registry.location
  repository = google_artifact_registry_repository.toto-reactjs-expenses-registry.name
  role       = "roles/artifactregistry.reader"
  member     = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_actions_environment_secret" "web_expenses_github_secret_expenses_endpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "EXPENSESV2_API_ENDPOINT"
    plaintext_value = var.toto_environment == "dev" ? format("https://api.%s.dr.nimat.fr/expenses", var.toto_environment) : "https://api.dr.nimat.fr/expenses"
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
resource "github_actions_environment_secret" "totoreactjsexpenses-secret-authendpoint" {
    repository = "toto-reactjs-expenses"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    plaintext_value = var.toto_environment == "dev" ? format("https://api.%s.dr.nimat.fr/auth", var.toto_environment) : "https://api.dr.nimat.fr/auth"
}