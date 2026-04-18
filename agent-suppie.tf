# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "agent-suppie-service-account" {
  account_id = "agent-suppie"
  display_name = "Toto Ex1 API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "agent-suppie-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.agent-suppie-service-account.email)
}
resource "google_project_iam_member" "agent-suppie-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.agent-suppie-service-account.email)
}
resource "google_project_iam_member" "agent-suppie-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.agent-suppie-service-account.email)
}
# ---------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "agent-suppie-registry" {
    location = var.gcp_region
    repository_id = "agent-suppie"
    format = "DOCKER"
    description = "Agent Suppie API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "agent-suppie-github-environment" {
    repository = "agent-suppie"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "agent-suppie-bucket-envsecret" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "agent-suppie-secret-cicdsakey" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "agent-suppie-var-pid" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "agent-suppie-secret-service-account" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.agent-suppie-service-account.email
}
resource "github_actions_environment_secret" "agent-suppie-secret-service-base-url" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://agent-suppie-%s/agentsuppie", var.cloud_run_endpoint_suffix)
}
resource "github_actions_environment_secret" "agent-suppie-secret-gale-broker-endpoint" {
    repository = "agent-suppie"
    environment = var.gcp_pid
    secret_name = "GALE_BROKER_URL"
    plaintext_value = format("https://gale-broker-%s/galebroker", var.cloud_run_endpoint_suffix)
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