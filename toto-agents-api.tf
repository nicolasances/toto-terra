# ###############################################################
# ###############################################################
# YOU CAN DELETE THIS FILE AFTER RUNNING TERRAFORM
# ###############################################################
# ###############################################################
# ---------------------------------------------------------------
# 0. Artifact Registry
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-agents-api-artifact-repo" {
    location = "europe-west1"
    repository_id = "toto-agents-api"
    description = "Artifact Registry for toto-agents-api"
    format = "DOCKER"
    
    docker_config {
        immutable_tags = true
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

# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-agents-api-service-account" {
  account_id = "toto-agents-api"
  display_name = "Agents API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-agents-api-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-agents-api-service-account.email)
}
resource "google_project_iam_member" "toto-agents-api-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-agents-api-service-account.email)
}
resource "google_project_iam_member" "toto-agents-api-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-agents-api-service-account.email)
}
resource "google_project_iam_member" "toto-agents-api-role-runinvoker" {
    project = var.gcp_pid
    role = "roles/run.invoker"
    member = format("serviceAccount:%s", google_service_account.toto-agents-api-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-agents-api-registry" {
    location = var.gcp_region
    repository_id = "toto-agents-api"
    format = "DOCKER"
    description = "Toto MS Agents API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-agents-api-github-environment" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-agents-api-bucket-envsecret" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto-agents-api-secret-cicdsakey" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-agents-api-var-pid" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-agents-api-secret-service-account" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-agents-api-service-account.email
}
resource "github_actions_environment_secret" "toto-agents-api-secret-service-base-url" {
    repository = "toto-agents-api"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://toto-agents-api-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "toto_agents_api_mongo_user" {
    description = "Mongo User for Agents API"
    type = string
    sensitive = true
}
variable "toto_agents_api_mongo_pswd" {
    description = "Mongo Password for Agents API"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-agents-api-mongo-user" {
    secret_id = "toto-agents-api-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-agents-api-mongo-user-version" {
    secret = google_secret_manager_secret.toto-agents-api-mongo-user.id
    secret_data = var.toto_agents_api_mongo_user
}
resource "google_secret_manager_secret" "toto-agents-api-mongo-pswd" {
    secret_id = "toto-agents-api-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-agents-api-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-agents-api-mongo-pswd.id
    secret_data = var.toto_agents_api_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
