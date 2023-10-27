
# ---------------------------------------------------------------
# Common Mongo Configuration
variable "mongo_host" {
    description = "Host for Mongo"
    type = string
    sensitive = true
}
resource "google_secret_manager_secret" "secret_mongo_host" {
    secret_id = "mongo-host"
    replication {
        auto { }
    }
}
resource "google_secret_manager_secret_version" "secret_mongo_host_version" {
    secret = google_secret_manager_secret.secret_mongo_host.id
    secret_data = var.mongo_host
}
