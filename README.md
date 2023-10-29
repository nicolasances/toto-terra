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

##### Note on Domain administration
Note that to automate the creation of Cloud Run Domain Mappings, the Service Account associated with Terraform needs to be authorized to **administer the domain**. <br>
To do that you need to:
 * Go on [Google Search Console](https://search.google.com/search-console/), where you will find your registered domain
 * Under `Settings > Users and Permissions` add the Terraform Service Account as a new user with **Owner permission**. *The Owner part is really important. Using "Full" permission is not enough and terraform won't be able to apply the changes*. 

### 1.2. Activate the necessary APIs
The following APIs need to be active, for Terraform to be able to integrate with GCP: 
 * Identity and Access Management (IAM) API 
 * Cloud Resource Manager API 