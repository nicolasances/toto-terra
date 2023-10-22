# Toto Terra
Terraform repository for Toto Projects.

## 1. GCP Configuration (pre-apply)
Before starting to apply Terraform plans, we need some initial configurations on GCP. 

### 1.1. Create a Service Account for Terraform
You need a Service Account to be created for terraform, in the target project. <br>
The Service Account should have these permissions:
 * `Editor` on the Project 
 * `Security Admin`
 * `Secret Manager Admin`

### 1.2. Activate the necessary APIs
The following APIs need to be active, for Terraform to be able to integrate with GCP: 
 * Identity and Access Management (IAM) API 
 * Cloud Resource Manager API 
 * Google Cloud Firestore API 