# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-tome-scraper-service-account" {
  account_id = "toto-ms-tome-scraper"
  display_name = "Tome Scraper API Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-tome-scraper-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-tome-scraper-service-account.email)
}
resource "google_project_iam_member" "toto-ms-tome-scraper-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-tome-scraper-service-account.email)
}
resource "google_project_iam_member" "toto-ms-tome-scraper-role-pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto-ms-tome-scraper-service-account.email)
}
# ---------------------------------------------------------------
# 2. Artifact Repository
# ---------------------------------------------------------------
resource "google_artifact_registry_repository" "toto-ms-tome-scraper-registry" {
    location = var.gcp_region
    repository_id = "toto-ms-tome-scraper"
    format = "DOCKER"
    description = "Tome Scraper API Artifact Registry"
    labels = {
        "created_by" = "terraform"
        "project" = var.gcp_pid
    }
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-tome-scraper-github-environment" {
    repository = "toto-ms-tome-scraper"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-tome-scraper-bucket-envsecret" {
    repository = "toto-ms-tome-scraper"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "toto-ms-tome-scraper-secret-cicdsakey" {
    repository = "toto-ms-tome-scraper"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "toto-ms-tome-scraper-var-pid" {
    repository = "toto-ms-tome-scraper"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "toto-ms-tome-scraper-secret-service-account" {
    repository = "toto-ms-tome-scraper"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-tome-scraper-service-account.email
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
resource "google_pubsub_subscription" "sub_tomescraper_to_topics" {
    name = "SupermarketEventToSelf"
    topic = google_pubsub_topic.topic_tome_topics.name

    ack_deadline_seconds = 30

    push_config {
      push_endpoint = format("https://toto-ms-tome-scraper-%s/events", var.cloud_run_endpoint_suffix)
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