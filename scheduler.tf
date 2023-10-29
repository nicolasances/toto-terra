# ---------------------------------------------------------------
# 1. Service Account
#    Service Account for Cloud Scheduler, used to inseract with 
#    other GCP services
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "cloud_scheduler_service_account" {
  account_id = "toto-cloud-scheduler"
  display_name = "Cloud Scheduler Service Account"
}
# ---------------------------------------------------------------
# 1.2. Service Account Roles
# ---------------------------------------------------------------
resource "google_project_iam_member" "cloud_scheduler_sa_role_cloud_run" {
    project = var.gcp_pid
    role = "roles/run.invoker"
    member = format("serviceAccount:%s", google_service_account.cloud_scheduler_service_account.email)
}

# ---------------------------------------------------------------
# 2. Job: Backup Expenses DB
# ---------------------------------------------------------------
resource "google_cloud_scheduler_job" "job_expenses_backup" {
  name             = "expenses-backup"
  description      = "Executes the backup of the Expenses Database"
  schedule         = "0 1 * * *"
  time_zone        = "Europe/Rome"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = format("https://expenses.api.%s.toto.nimatz.com/backup", var.toto_environment)
    headers = {
      "auth-provider" = "google"
      "x-client-id" = format("https://expenses.api.%s.toto.nimatz.com/backup", var.toto_environment)
      "x-correlation-id" = format("cs-%s", formatdate("YYYYMMDDhhmmss", timestamp()))
    }
    
    oidc_token {
      service_account_email = google_service_account.cloud_scheduler_service_account.email
    }
  }
}
