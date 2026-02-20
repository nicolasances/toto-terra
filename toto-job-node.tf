# ---------------------------------------------------------------
# 1. Service Account
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto_job_node_service_account" {
  account_id = "toto-job-node"
  display_name = "Toto Job Node Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto_job_node_role_secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto_job_node_service_account.email)
}
resource "google_project_iam_member" "toto_job_node_role_gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto_job_node_service_account.email)
}
resource "google_project_iam_member" "toto_job_node_role_pubsub" {
    project = var.gcp_pid
    role = "roles/pubsub.publisher"
    member = format("serviceAccount:%s", google_service_account.toto_job_node_service_account.email)
}
resource "google_project_iam_member" "toto_job_node_role_aiplatform" {
    project = var.gcp_pid
    role = "roles/aiplatform.user"
    member = format("serviceAccount:%s", google_service_account.toto_job_node_service_account.email)
}