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
    repository_id = "toto-react-supermarket"
    format = "DOCKER"
    description = "Toto Suppie API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    # No cleanup policy on purpose: the GKE Deployment (toto-terra-gke) pins an image tag,
    # which must never be deleted. If one is ever added, use only KEEP most_recent_versions
    # (no time-based DELETE rule).
}

# Allow the GKE nodes (toto-terra-gke, other GCP project) to pull images from this registry
resource "google_artifact_registry_repository_iam_member" "web_suppie_registry_gke_reader" {
  project    = google_artifact_registry_repository.web_suppie_registry.project
  location   = google_artifact_registry_repository.web_suppie_registry.location
  repository = google_artifact_registry_repository.web_suppie_registry.name
  role       = "roles/artifactregistry.reader"
  member     = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
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
    # toto-ms-supermarket runs on GKE
    plaintext_value  = format("https://%s/supermarket", var.gke_api_hostname)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_games_endpoint" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "AUTH_API_ENDPOINT"
    # toto-ms-auth runs on GKE
    plaintext_value  = format("https://%s/auth", var.gke_api_hostname)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_gale_broker_endpoint" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "GALE_BROKER_API_ENDPOINT"
    plaintext_value  = format("https://gale-broker-%s/galebroker", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "web_suppie_github_secret_whispering_endpoint" {
    repository = "toto-suppie"
    environment = var.toto_environment
    secret_name = "WHISPERING_API_ENDPOINT"
    plaintext_value = format("https://api.%s.toto.nimoto.eu/whispering", var.toto_environment)
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
resource "github_actions_environment_variable" "web_suppie_github_envvar_gke_project_id" {
    repository = "toto-suppie"
    environment = var.toto_environment
    variable_name = "GKE_PROJECT_ID"
    value = var.gke_project_id
}
resource "github_actions_environment_variable" "web_suppie_github_envvar_gke_cluster_name" {
    repository = "toto-suppie"
    environment = var.toto_environment
    variable_name = "GKE_CLUSTER_NAME"
    value = var.gke_cluster_name
}
resource "github_actions_environment_variable" "web_suppie_github_envvar_gke_cluster_location" {
    repository = "toto-suppie"
    environment = var.toto_environment
    variable_name = "GKE_CLUSTER_LOCATION"
    value = var.gke_cluster_location
}
resource "github_actions_environment_variable" "web_suppie_github_envvar_gke_namespace" {
    repository = "toto-suppie"
    environment = var.toto_environment
    variable_name = "GKE_NAMESPACE"
    value = var.toto_environment
}

# ---------------------------------------------------------------
# 4. GKE Cluster authorization
# The app is also hosted in the GKE cluster of another GCP project (toto-terra-gke).
# Its pods (KSA toto-react-supermarket in the environment namespace) call Speech-to-Text and
# Text-to-Speech from the server-side API routes, with this Workload Identity principal.
# ---------------------------------------------------------------
locals {
    web_suppie_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/toto-react-supermarket",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
# A federated principal has no home project: the pods set GOOGLE_CLOUD_QUOTA_PROJECT to this
# project, which requires serviceusage.services.use on it to bill/quota the STT and TTS calls here.
# Speech-to-Text v1 and Text-to-Speech should need no other role (the Cloud Run service account has none): to verify on GKE.
resource "google_project_iam_member" "web_suppie_gke_role_serviceusage" {
    project = var.gcp_pid
    role = "roles/serviceusage.serviceUsageConsumer"
    member = local.web_suppie_gke_principal
}
