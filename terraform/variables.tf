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
variable "gcp_service_account_key_file" {
    description = "Terraform Service Account key file"
    type = string
}
# ---------------------------------------------------------
# Github variables
# ---------------------------------------------------------
variable "git_env_prefix" {
    description = "Prefix of the github action secrets"
    type = string
}
variable "git_token" {
    description = "Access token used to authenticate to Github"
    type = string
    sensitive = true
}