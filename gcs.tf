# ---------------------------------------------------------------
# Storage Buckets
# ---------------------------------------------------------------
resource "google_storage_bucket" "backup-bucket" {
    name = format("%s-expenses-backup-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}
resource "google_storage_bucket" "models-bucket" {
    name = format("%s-models-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}
resource "google_storage_bucket" "supermarket-backup-bucket" {
    name = format("%s-supermarket-backup-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}
resource "google_storage_bucket" "tome-bucket" {
    name = format("%s-tome-bucket", var.gcp_pid)
    location = "EU"
    force_destroy = false
    uniform_bucket_level_access = true
}
