# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-auth-service-account" {
  account_id = "toto-ms-auth"
  display_name = "Auth Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-auth-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-auth-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-auth-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-auth"
    format = "DOCKER"
    description = "Toto MS Auth Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }

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

# Allow public access to the Artifact Registry repository (to pull images without authentication)
# Needed by the GKE cluster (toto-terra-gke), which pulls the image from this project's registry
resource "google_artifact_registry_repository_iam_member" "toto-ms-auth-public" {
  project    = google_artifact_registry_repository.toto-ms-auth-registry.project
  location   = google_artifact_registry_repository.toto-ms-auth-registry.location
  repository = google_artifact_registry_repository.toto-ms-auth-registry.name
  role       = "roles/artifactregistry.reader"
  member     = "allUsers"
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-auth-github-environment" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsauth-secret-cicdsakey" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomsauth-var-pid" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsauth-secret-service-account" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-auth-service-account.email
}
resource "github_actions_environment_variable" "totomsauth-var-gke-project-id" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    variable_name = "GKE_PROJECT_ID"
    value = var.gke_project_id
}
resource "github_actions_environment_variable" "totomsauth-var-gke-cluster-name" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    variable_name = "GKE_CLUSTER_NAME"
    value = var.gke_cluster_name
}
resource "github_actions_environment_variable" "totomsauth-var-gke-cluster-location" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    variable_name = "GKE_CLUSTER_LOCATION"
    value = var.gke_cluster_location
}
resource "github_actions_environment_variable" "totomsauth-var-gke-namespace" {
    repository = "toto-ms-auth"
    environment = var.gcp_pid
    variable_name = "GKE_NAMESPACE"
    value = var.toto_environment
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 7. GKE Cluster authorization
# Use this when hosting this microservice in a GKE cluster in another GCP project, to access the toto GCP projects (dev and prod)
# ---------------------------------------------------------------
locals {
    toto_ms_auth_gke_principal = format(
        "principal://iam.googleapis.com/projects/%s/locations/global/workloadIdentityPools/%s.svc.id.goog/subject/ns/%s/sa/toto-ms-auth",
        var.gke_project_number,
        var.gke_project_id,
        var.toto_environment,
    )
}
resource "google_project_iam_member" "toto-ms-auth-gke-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = local.toto_ms_auth_gke_principal
}
