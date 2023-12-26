# ---------------------------------------------------------------
# 1. Service Account
#    Service Account for Cloud Scheduler, used to inseract with 
#    other GCP services
# ---------------------------------------------------------------
# 1.1. Service Account 
# ---------------------------------------------------------------
resource "google_service_account" "cloud_scheduler_service_account" {
  account_id = "toto-scheduler"
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
    uri         = format("https://toto-ms-expenses-%s/backup", var.cloud_run_endpoint_suffix)
    headers = {
      "auth-provider" = "google"
      "x-client-id" = format("https://toto-ms-expenses-%s/backup", var.cloud_run_endpoint_suffix)
      "x-correlation-id" = "cloud-sched"
    }
    
    oidc_token {
      service_account_email = google_service_account.cloud_scheduler_service_account.email
      audience = var.target_audience
    }
  }
}
resource "google_cloud_scheduler_job" "job_kud_backup" {
  name             = "kud-backup"
  description      = "Executes the backup of the Kud Database"
  schedule         = "0 1 * * *"
  time_zone        = "Europe/Rome"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = format("https://toto-ms-kud-%s/backup", var.cloud_run_endpoint_suffix)
    headers = {
      "auth-provider" = "google"
      "x-client-id" = format("https://toto-ms-kud-%s/backup", var.cloud_run_endpoint_suffix)
      "x-correlation-id" = "cloud-sched"
    }
    
    oidc_token {
      service_account_email = google_service_account.cloud_scheduler_service_account.email
      audience = var.target_audience
    }
  }
}
resource "google_cloud_scheduler_job" "job_games_backup" {
  name             = "games-backup"
  description      = "Executes the backup of the Games Database"
  schedule         = "0 1 * * *"
  time_zone        = "Europe/Rome"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = format("https://toto-ms-games-%s/backup", var.cloud_run_endpoint_suffix)
    headers = {
      "auth-provider" = "google"
      "x-client-id" = format("https://toto-ms-games-%s/backup", var.cloud_run_endpoint_suffix)
      "x-correlation-id" = "cloud-sched"
    }
    
    oidc_token {
      service_account_email = google_service_account.cloud_scheduler_service_account.email
      audience = var.target_audience
    }
  }
}
