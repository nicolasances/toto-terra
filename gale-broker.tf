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
resource "google_service_account" "gale-broker-service-account" {
  account_id = "gale-broker"
  display_name = "Gale Broker Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "gale-broker-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.gale-broker-service-account.email)
}
resource "google_project_iam_member" "gale-broker-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.gale-broker-service-account.email)
}
resource "google_project_iam_member" "gale-broker-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.gale-broker-service-account.email)
}

# --------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "gale-broker-registry" {
    location = var.gcp_region
    repository_id = "gale-broker"
    format = "DOCKER"
    description = "Gale Broker Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "gale-broker-github-environment" {
    repository = "gale-broker"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "gale-broker-bucket-envsecret" {
    repository = "gale-broker"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "gale-broker-secret-cicdsakey" {
    repository = "gale-broker"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "gale-broker-var-pid" {
    repository = "gale-broker"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "gale-broker-secret-service-account" {
    repository = "gale-broker"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.gale-broker-service-account.email
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "gale_broker_mongo_user" {
    description = "Mongo User for Gale Broker"
    type = string
    sensitive = true
}
variable "gale_broker_mongo_pswd" {
    description = "Mongo Password for Gale Broker"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "gale-broker-mongo-user" {
    secret_id = "gale-broker-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "gale-broker-mongo-user-version" {
    secret = google_secret_manager_secret.gale-broker-mongo-user.id
    secret_data = var.gale_broker_mongo_user
}
resource "google_secret_manager_secret" "gale-broker-mongo-pswd" {
    secret_id = "gale-broker-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "gale-broker-mongo-pswd-version" {
    secret = google_secret_manager_secret.gale-broker-mongo-pswd.id
    secret_data = var.gale_broker_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
resource "google_pubsub_subscription" "sub_galebroker_to_agents" {
    name = "GaleBrokerToAgents"
    topic = google_pubsub_topic.topic_gale_agents.name

    ack_deadline_seconds = 600

    push_config {
      push_endpoint = format("https://gale-broker-%s/events/topic", var.cloud_run_endpoint_suffix)
      oidc_token {
        service_account_email = google_service_account.toto-pubsub-service-account.email
        audience = var.target_audience
      }
    }

    expiration_policy {
      ttl = ""
    }

    retry_policy {
      minimum_backoff = "10s"
      maximum_backoff = "600s"
    }
}