# Terraform Google IAM Module

This module manages IAM resources for the fintech production infrastructure, including:

- GKE IAM resources (host service agent, workload identity)
- Cloud SQL IAM resources (admin and client service accounts)
- OS Login IAM resources
- Bastion IAM resources
- IAP Tunnel IAM resources

## Usage

```hcl
module "iam" {
  source = "../modules/terraform-google-iam"

  enable_gke_iam = true
  enable_sql_iam = true
  enable_os_login_iam = true
  enable_bastion_iam = true
  enable_iap_tunnel_iam = true

  host_project_id = "host-project"
  gke_project_id  = "gke-project"
  data_project_id = "data-project"

  gke_workload_identity_service_accounts = {
    "example-sa" = {
      display_name               = "Example Service Account"
      description                = "Example workload identity service account"
      kubernetes_namespace       = "default"
      kubernetes_service_account = "example-sa"
      gcp_roles                  = ["roles/storage.admin"]
    }
  }

  os_login_users = [
    "user:user1@fintech.com",
    "user:user2@fintech.com"
  ]

  iap_tunnel_users = [
    "user:user1@fintech.com",
    "user:user2@fintech.com"
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_gke_iam | Enable GKE IAM resources | `bool` | `false` | no |
| enable_sql_iam | Enable Cloud SQL IAM resources | `bool` | `false` | no |
| enable_os_login_iam | Enable OS Login IAM resources | `bool` | `false` | no |
| enable_bastion_iam | Enable Bastion IAM resources | `bool` | `false` | no |
| enable_iap_tunnel_iam | Enable IAP Tunnel IAM resources | `bool` | `false` | no |
| host_project_id | Host project ID for GKE | `string` | `""` | no |
| gke_project_id | GKE project ID | `string` | `""` | no |
| data_project_id | Data project ID for Cloud SQL | `string` | `""` | no |
| gke_workload_identity_service_accounts | GKE workload identity service accounts configuration | `map(object)` | `{}` | no |
| os_login_users | List of IAM users to grant OS Login access | `list(string)` | `[]` | no |
| iap_tunnel_users | List of IAM users to grant IAP Tunnel access | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| gke_workload_identity_service_accounts | GKE workload identity service account emails |
| cloudsql_admin_service_account_email | Cloud SQL admin service account email |
| cloudsql_admin_service_account_name | Cloud SQL admin service account name |
| cloudsql_admin_service_account_id | Cloud SQL admin service account ID |
| gke_service_account_email | GKE service account email |
| gke_service_account_name | GKE service account name |
| gke_service_account_id | GKE service account ID |
| iap_tunnel_users | List of users with IAP Tunnel access | 