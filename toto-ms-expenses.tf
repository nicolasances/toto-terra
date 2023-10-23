# Create the Service Account
resource "google_service_account" "toto-ms-expenses-service-account" {
  account_id = "toto-ms-expenses"
  display_name = "Expenses Service Account"
}

# Provide IAM roles to Service Account
resource "google_project_iam_member" "toto-ms-expenses-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}
resource "google_project_iam_member" "toto-ms-expenses-role-firestore" {
    project = var.gcp_pid
    role = "roles/datastore.owner"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}
resource "google_project_iam_member" "toto-ms-expenses-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}