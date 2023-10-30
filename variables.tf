# ---------------------------------------------------------------
# 1. GCP Project Variables
# ---------------------------------------------------------------
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
# ---------------------------------------------------------------
# 2. Toto Environment Variables
# ---------------------------------------------------------------
variable "toto_environment" {
    description = "The environment (dev, prod)"
    type = string
}
# ---------------------------------------------------------------
# 3. Cloud Run Variables
# ---------------------------------------------------------------
variable "cloud_run_endpoint_suffix" {
    description = "Suffix that Cloud Run appends to the service name to provide an HTTPS endpoint"
    type = string
}