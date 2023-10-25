terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "4.11.0"
        }
        github = {
            source  = "integrations/github"
            version = "5.40.0"
        }
    }
    # backend "gcs" {
    #     prefix = "terraform/state"
    #     credentials = "~/pleggit-terraform-key.json"
    # }
}

provider "google" {
    credentials = var.gcp_service_account_key

    project = var.gcp_pid
    region = var.gcp_region
    zone = var.gcp_zone
    
}
provider "google-beta" {
    credentials = var.gcp_service_account_key

    project = var.gcp_pid
    region = var.gcp_region
    zone = var.gcp_zone
    
}

provider "github" {
    token = var.git_token
}
