# ###############################################################
# ###############################################################
# ape-tasks
#
# Microservice hosted on the external GKE cluster (toto-terra-gke) and on Cloud Run.
# Built from the template gke-external/terraform/toto-ms-xxx.toto-terra.tf of the ape-tasks repo.
# Applied once per environment (totoexperiments = dev, totolive = prod).
#
# ape-tasks has no database: there are no Mongo secrets (section 3 of the template is removed).
# ###############################################################
# ###############################################################

# ---------------------------------------------------------------
# 1. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "ape-tasks-registry" {
    location = var.gcp_region
    repository_id = "ape-tasks"
    format = "DOCKER"
    description = "Ape Tasks Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

    cleanup_policy_dry_run = false
    cleanup_policies {
        id     = "keep-minimum-versions"
        action = "KEEP"
        most_recent_versions {
            keep_count            = 1
        }
    }
}

# The GKE nodes (service account gke-nodes of the GKE project) pull the images of this repository
resource "google_artifact_registry_repository_iam_member" "ape-tasks-registry-gke-reader" {
    project = google_artifact_registry_repository.ape-tasks-registry.project
    location = google_artifact_registry_repository.ape-tasks-registry.location
    repository = google_artifact_registry_repository.ape-tasks-registry.name
    role = "roles/artifactregistry.reader"
    member = format("serviceAccount:gke-nodes@%s.iam.gserviceaccount.com", var.gke_project_id)
}

# ---------------------------------------------------------------
# 2. Github environment secrets & variables (used by the release-*.yml workflows)
# ---------------------------------------------------------------
resource "github_repository_environment" "ape-tasks-github-environment" {
    repository = "ape-tasks"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "ape-tasks-secret-cicdsakey" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "ape-tasks-var-pid" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
# The GKE cluster the pipeline deploys to (kubectl set image), and the namespace of this environment (dev or prod)
resource "github_actions_environment_variable" "ape-tasks-var-gke-project-id" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    variable_name = "GKE_PROJECT_ID"
    value = var.gke_project_id
}
resource "github_actions_environment_variable" "ape-tasks-var-gke-cluster-name" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    variable_name = "GKE_CLUSTER_NAME"
    value = var.gke_cluster_name
}
resource "github_actions_environment_variable" "ape-tasks-var-gke-cluster-location" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    variable_name = "GKE_CLUSTER_LOCATION"
    value = var.gke_cluster_location
}
resource "github_actions_environment_variable" "ape-tasks-var-gke-namespace" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    variable_name = "GKE_NAMESPACE"
    value = var.toto_environment
}

# ---------------------------------------------------------------
# 3. GKE Cluster authorization
# The pod runs as the Kubernetes Service Account "ape-tasks" in the namespace of the
# environment (var.toto_environment: dev or prod). Through Workload Identity Federation
# for GKE, it is this principal in IAM: roles are granted to it directly (no Google SA, no key).
# ---------------------------------------------------------------
locals {
    ape_tasks_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/ape-tasks",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
resource "google_project_iam_member" "ape-tasks-gke-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = local.ape_tasks_gke_principal
}

# ---------------------------------------------------------------
# 4. Cloud Run
# ---------------------------------------------------------------
# 4.1. Service Account the Cloud Run service runs as
resource "google_service_account" "ape-tasks-service-account" {
    account_id = "ape-tasks"
    display_name = "Ape Tasks Service Account"
}
resource "google_project_iam_member" "ape-tasks-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.ape-tasks-service-account.email)
}

# 4.2. Github environment secrets used by the "Deploy to Cloud Run" step
resource "github_actions_environment_secret" "ape-tasks-secret-service-account" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.ape-tasks-service-account.email
}
resource "github_actions_environment_secret" "ape-tasks-secret-service-base-url" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://ape-tasks-%s", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "ape-tasks-secret-gale-broker-endpoint" {
    repository = "ape-tasks"
    environment = var.gcp_pid
    secret_name = "GALE_BROKER_URL"
    plaintext_value = format("https://gale-broker-%s/galebroker", var.cloud_run_endpoint_suffix)
}
