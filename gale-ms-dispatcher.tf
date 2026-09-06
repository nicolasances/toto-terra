# ###############################################################
# ###############################################################
# YOU CAN DELETE THIS FILE AFTER RUNNING TERRAFORM
# ###############################################################
# ###############################################################

# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "gale-ms-dispatcher-service-account" {
  account_id = "gale-ms-dispatcher"
  display_name = "Gale Dispatcher API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "gale-ms-dispatcher-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.gale-ms-dispatcher-service-account.email)
}
resource "google_project_iam_member" "gale-ms-dispatcher-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.gale-ms-dispatcher-service-account.email)
}
resource "google_project_iam_member" "gale-ms-dispatcher-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.gale-ms-dispatcher-service-account.email)
}
# UNCOMMENT IF WORKING WITH AI 
# resource "google_project_iam_member" "gale-ms-dispatcher_role_aiplatform" {
#     project = var.gcp_pid
#     role = "roles/aiplatform.user"
#     member = format("serviceAccount:%s", google_service_account.gale-ms-dispatcher-service-account.email)
# }


# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "gale-ms-dispatcher-registry" {
    location = var.gcp_region
    repository_id = "gale-ms-dispatcher"
    format = "DOCKER"
    description = "Gale Dispatcher Artifact Registry"
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

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "gale-ms-dispatcher-github-environment" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "gale-ms-dispatcher-bucket-envsecret" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "gale-ms-dispatcher-secret-cicdsakey" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "gale-ms-dispatcher-var-pid" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "gale-ms-dispatcher-secret-service-account" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.gale-ms-dispatcher-service-account.email
}
resource "github_actions_environment_secret" "gale-ms-dispatcher-secret-service-base-url" {
    repository = "gale-ms-dispatcher"
    environment = var.gcp_pid
    secret_name = "SERVICE_BASE_URL"
    plaintext_value = format("https://gale-ms-dispatcher-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "gale_ms_dispatcher_mongo_user" {
    description = "Mongo User for Gale Dispatcher"
    type = string
    sensitive = true
}
variable "gale_ms_dispatcher_mongo_pswd" {
    description = "Mongo Password for Gale Dispatcher"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "gale-ms-dispatcher-mongo-user" {
    secret_id = "gale-ms-dispatcher-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "gale-ms-dispatcher-mongo-user-version" {
    secret = google_secret_manager_secret.gale-ms-dispatcher-mongo-user.id
    secret_data = var.gale_ms_dispatcher_mongo_user
}
resource "google_secret_manager_secret" "gale-ms-dispatcher-mongo-pswd" {
    secret_id = "gale-ms-dispatcher-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "gale-ms-dispatcher-mongo-pswd-version" {
    secret = google_secret_manager_secret.gale-ms-dispatcher-mongo-pswd.id
    secret_data = var.gale_ms_dispatcher_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
