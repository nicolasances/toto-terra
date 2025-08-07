# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "tome-ms-topics-service-account" {
  account_id = "tome-ms-topics"
  display_name = "Tome Topics API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "tome-ms-topics-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}
resource "google_project_iam_member" "tome-ms-topics-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}
resource "google_project_iam_member" "tome-ms-topics-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.tome-ms-topics-service-account.email)
}
# ---------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "tome-ms-topics-registry" {
    location = var.gcp_region
    repository_id = "tome-ms-topics"
    format = "DOCKER"
    description = "Tome Topics API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "tome-ms-topics-github-environment" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-topics-bucket-envsecret" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "tome-ms-topics-secret-cicdsakey" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "tome-ms-topics-var-pid" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "tome-ms-topics-secret-service-account" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.tome-ms-topics-service-account.email
}
resource "github_actions_environment_variable" "tome_ms_topics_github_envvar_flashcards_endpoint" {
    repository = "tome-ms-topics"
    environment = var.gcp_pid
    variable_name = "TOME_FLASHCARDS_API_ENDPOINT"
    value = format("https://tome-ms-flashcards-%s", var.cloud_run_endpoint_suffix)
}

# ---------------------------------------------------------------
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
variable "tome_ms_topics_mongo_user" {
    description = "Mongo User for Tome Topics API"
    type = string
    sensitive = true
}
variable "tome_ms_topics_mongo_pswd" {
    description = "Mongo Password for Tome Topics API"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "tome-ms-topics-mongo-user" {
    secret_id = "tome-ms-topics-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-topics-mongo-user-version" {
    secret = google_secret_manager_secret.tome-ms-topics-mongo-user.id
    secret_data = var.tome_ms_topics_mongo_user
}
resource "google_secret_manager_secret" "tome-ms-topics-mongo-pswd" {
    secret_id = "tome-ms-topics-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "tome-ms-topics-mongo-pswd-version" {
    secret = google_secret_manager_secret.tome-ms-topics-mongo-pswd.id
    secret_data = var.tome_ms_topics_mongo_pswd
}

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
# 5.2. Domain Mapping

# ---------------------------------------------------------------
# 6. PubSub Subscriptions to events
# ---------------------------------------------------------------
resource "google_pubsub_subscription" "sub_tome_practice_to_topic" {
    name = "PracticeEventsToTomeTopics"
    topic = google_pubsub_topic.topic_tome_practice.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://tome-ms-topics-%s/events/practice", var.cloud_run_endpoint_suffix)
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
resource "google_pubsub_subscription" "sub_tometopics_to_topic" {
    name = "TopicsToTomeTopic"
    topic = google_pubsub_topic.topic_tome_topics.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://tome-ms-topics-%s/events/topic", var.cloud_run_endpoint_suffix)
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