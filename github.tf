# ---------------------------------------------------------------
# Service Account for Github Actions
# ---------------------------------------------------------------
resource "google_service_account" "toto-cicd-service-account" {
  account_id = "toto-cicd"
  display_name = "CI/CD Service Account"
}
resource "google_service_account_key" "toto-cicd-sa-key" {
    service_account_id = google_service_account.toto-cicd-service-account.name
}

# Grant the right roles to the CI CD service account
resource "google_project_iam_member" "ci-cd-roles-runadmin" {
    project = var.gcp_pid
    role = "roles/run.admin"
    member = format("serviceAccount:%s", google_service_account.toto-cicd-service-account.email)
}
resource "google_project_iam_member" "ci-cd-roles-serviceaccountuser" {
    project = var.gcp_pid
    role = "roles/iam.serviceAccountUser"
    member = format("serviceAccount:%s", google_service_account.toto-cicd-service-account.email)
}
resource "google_project_iam_member" "ci-cd-roles-storageadmin" {
    project = var.gcp_pid
    role = "roles/storage.admin"
    member = format("serviceAccount:%s", google_service_account.toto-cicd-service-account.email)
}
resource "google_project_iam_member" "ci-cd-roles-storageobjectviewer" {
    project = var.gcp_pid
    role = "roles/storage.objectViewer"
    member = format("serviceAccount:%s", google_service_account.toto-cicd-service-account.email)
}
resource "google_project_iam_member" "ci-cd-roles-artifactregistryadmin" {
    project = var.gcp_pid
    role = "roles/artifactregistry.admin"
    member = format("serviceAccount:%s", google_service_account.toto-cicd-service-account.email)
}

# ---------------------------------------------------------
# Github variables
# ---------------------------------------------------------
variable "git_token" {
    description = "Access token used to authenticate to Github"
    type = string
    sensitive = true
}
