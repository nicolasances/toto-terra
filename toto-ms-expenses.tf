# Create the Service Account
resource "google_service_account" "toto-ms-expenses-service-account" {
  account_id = "toto-ms-expenses"
  display_name = "Expenses Service Account"
}

# ---------------------------------------------------------------
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

# ---------------------------------------------------------------
# Storage Bucket to store the backups
resource "google_storage_bucket" "backup-bucket" {
    name = format("%s-expenses-backup-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}

# ---------------------------------------------------------------
# Github environment secrets 
resource "github_actions_environment_secret" "toto_backup_bucket_envsecret" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "backup-bucket"
    plaintext_value   = github_actions_environment_secret.toto_backup_bucket_envsecret.name
}