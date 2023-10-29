# ---------------------------------------------------------------
# 1. Service Account 
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "toto-ms-expenses-service-account" {
  account_id = "toto-ms-expenses"
  display_name = "Expenses Service Account"
}

# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "toto-ms-expenses-role-secretmanagedaccessor" {
    project = var.gcp_pid
    role = "roles/secretmanager.secretAccessor"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}
resource "google_project_iam_member" "toto-ms-expenses-role-gcs" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-ms-expenses-service-account.email)
}

# ---------------------------------------------------------------
# 2. Storage Bucket 
# ---------------------------------------------------------------
resource "google_storage_bucket" "backup-bucket" {
    name = format("%s-expenses-backup-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}

# ---------------------------------------------------------------
# 3. Github environment secrets & variables
# ---------------------------------------------------------------
resource "github_repository_environment" "toto-ms-expenses-github-environment" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
}
resource "github_actions_environment_secret" "toto_backup_bucket_envsecret" {
    repository = "toto-ms-expenses"
    environment = var.gcp_pid
    secret_name = "BACKUP_BUCKET"
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
# 4. Google Secret Manager (Secrets)
# ---------------------------------------------------------------
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

# ---------------------------------------------------------------
# 5. Cloud DNS & Domain Mapping
# ---------------------------------------------------------------
# 5.1. DNS 
resource "google_dns_record_set" "api_expenses_dns" {
  name = format("expenses.api.%s.toto", var.toto_environment)
  rrdatas = ["ghs.googlehosted.com."]
  type = "CNAME"
  ttl  = 3600
  managed_zone = google_dns_managed_zone.dns_zone.name
  project = var.gcp_pid
}
# 5.2. Domain Mapping
resource "google_cloud_run_domain_mapping" "api_expenses_domain_mapping" {
  location = var.gcp_region
  name = format("expenses.api.%s.toto.nimatz.com", var.toto_environment)
  spec {
    route_name = "toto-ms-expenses"
  }
  metadata {
    namespace = var.gcp_pid
  }
}
