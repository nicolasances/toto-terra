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
variable "gcp_project_number" {
    description = "Project number on GCP"
    type = string
}
# ---------------------------------------------------------------
# 2. Toto Environment Variables
# ---------------------------------------------------------------
variable "toto_environment" {
    description = "The environment (dev, prod)"
    type = string
}
variable "toto_aws_environment" {
    description = "The AWS environment (dev, prod)"
    type = string
}
# ---------------------------------------------------------------
# 3. Cloud Run Variables
# ---------------------------------------------------------------
variable "cloud_run_endpoint_suffix" {
    description = "Suffix that Cloud Run appends to the service name to provide an HTTPS endpoint"
    type = string
}
# ---------------------------------------------------------------
# 4. Other
# ---------------------------------------------------------------
variable "web_google_client_id" {
    description = "Client ID for the frontends to use"
    type = string
    sensitive = true
}
variable "aws_sandbox_llm_api" {
    description = "API endpoint for the AWS Sandbox-hosted LLM"
    type = string
    sensitive = true
}
variable "openai_api_key" {
    description = "OpenAI API Key"
    type = string
    sensitive = true
}

# ---------------------------------------------------------------
# 5. GKE Cluster Variables
# Used by workkloads hosted in a GKE cluster in another GCP project to access the toto GCP projects (dev and prod)
# ---------------------------------------------------------------
variable "gke_project_id" {
    description = "ID of the GCP project hosting the GKE cluster"
    type = string
}
variable "gke_project_number" {
    description = "Number of the GCP project hosting the GKE cluster"
    type = string
}