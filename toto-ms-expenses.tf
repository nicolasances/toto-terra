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
# Github environment secrets & variables
resource "github_repository_environment" "toto-ms-expenses-github-environment" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto_backup_bucket_envsecret" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "backup_bucket"
    plaintext_value  = google_storage_bucket.backup-bucket.name
}
resource "github_actions_environment_secret" "totomsexpenses-secret-cicdsakey" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "CICD_SERVICE_ACCOUNT"
    plaintext_value = jsonencode(jsondecode(base64decode(google_service_account_key.toto-cicd-sa-key.private_key)))
}
resource "github_actions_environment_variable" "totomsexpenses-var-pid" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    variable_name = "GCP_PID"
    value = var.gcp_pid
}
resource "github_actions_environment_secret" "totomsexpenses-secret-service-account" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "SERVICE_ACCOUNT"
    plaintext_value = google_service_account.toto-ms-expenses-service-account.email
}

# ---------------------------------------------------------------
# Secrets needed by this service
variable "toto_ms_expenses_mongo_user" {
    description = "Mongo User for expenses"
    type = string
    sensitive = true
}
variable "toto_ms_expenses_mongo_pswd" {
    description = "Mongo Password for expenses"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "toto-ms-expenses-mongo-user" {
    secret_id = "toto-ms-expenses-mongo-user"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-expenses-mongo-user-version" {
    secret = google_secret_manager_secret.toto-ms-expenses-mongo-user.id
    secret_data = var.toto_ms_expenses_mongo_user
}
resource "google_secret_manager_secret" "toto-ms-expenses-mongo-pswd" {
    secret_id = "toto-ms-expenses-mongo-pswd"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "toto-ms-expenses-mongo-pswd-version" {
    secret = google_secret_manager_secret.toto-ms-expenses-mongo-pswd.id
    secret_data = var.toto_ms_expenses_mongo_pswd
}
