# ---------------------------------------------------------------
# 1. Service Account for PubSub
# ---------------------------------------------------------------
# 1.1. Create the Service Account
# ---------------------------------------------------------------
resource "google_service_account" "toto-pubsub-service-account" {
  account_id = "toto-pubsub"
  display_name = "PubSub Service Account"
}

# ---------------------------------------------------------------
# 1.2. Provide IAM roles to Service Account
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-pubsub-role-cloudrun" {
    project = var.gcp_pid
    role = "roles/run.invoker"
    member = format("serviceAccount:%s", google_service_account.toto-pubsub-service-account.email)
}
resource "google_project_iam_member" "toto-pubsub-role-tokencreator" {
    project = var.gcp_pid
    role = "roles/iam.serviceAccountTokenCreator"
    member = format("serviceAccount:%s", google_service_account.toto-pubsub-service-account.email)
}

# ---------------------------------------------------------------
# 2. Topics
# ---------------------------------------------------------------
resource "google_pubsub_topic" "topic_expenses" {
    name = "expenses"
}
resource "google_pubsub_topic" "topic_tags" {
    name = "tags"
}
resource "google_pubsub_topic" "topic_games" {
    name = "games"
}
resource "google_pubsub_topic" "topic_kuds" {
    name = "kuds"
}
resource "google_pubsub_topic" "topic_supermarket" {
    name = "supermarket"
}
resource "google_pubsub_topic" "topic_tome_topics" {
    name = "tometopics"
}
resource "google_pubsub_topic" "topic_tome_practice" {
    name = "tomepractices"
}
resource "google_pubsub_topic" "topic_tome_flashcards" {
    name = "tomeflashcards"
}
resource "google_pubsub_topic" "topic_gale_agents" {
    name = "galeagents"
}

# ---------------------------------------------------------------
# 3. Secrets for Topic Names
# ---------------------------------------------------------------
resource "google_secret_manager_secret" "topic_name_tometopics_secret" {
  secret_id = "tome_topics_topic_name"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "topic_name_tometopics_secret_version" {
  secret = google_secret_manager_secret.topic_name_tometopics_secret.id
  secret_data = google_pubsub_topic.topic_tome_topics.name
}

# Supermarket topic secret
resource "google_secret_manager_secret" "topic_name_supermarket_secret" {
  secret_id = "topic-name-supermarket"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "topic_name_supermarket_secret_version" {
  secret = google_secret_manager_secret.topic_name_supermarket_secret.id
  secret_data = google_pubsub_topic.topic_supermarket.name
}