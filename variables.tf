variable "gcp_pid" {
  description = "GCP Project ID"
  type = string
}
variable "gcp_region" {
    description = "GCP Region"
    type = string
    default = "europe-west1"
}
variable "gcp_zone" {
    description = "GCP Zone"
    type = string
    default = "europe-west1-c"
}
variable "gcp_service_account_key" {
    description = "Terraform Service Account key"
    type = string
}
