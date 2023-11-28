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

