# Terraform Google VPC Service Controls Module

This module provides comprehensive VPC Service Controls and Access Context Manager configuration for the fintech production infrastructure.

## Features

- **Access Context Manager Policy**: Centralized access control policy
- **Multiple Access Levels**: Configurable access levels for different teams and service accounts
- **Service Perimeters**: Three-tier perimeter architecture for enhanced security
- **Dynamic Configuration**: All users, service accounts, and services are configurable via variables

## Architecture

### Access Levels

The module creates the following access levels (only if members are provided):

1. **DevOps Team**: Full access for infrastructure management
2. **Backend Team**: Backend-specific access
3. **Frontend Team**: Frontend-specific access  
4. **Mobile Team**: Mobile-specific access
5. **Service Accounts**: Infrastructure service accounts
6. **GKE Workload Identity**: Kubernetes workload identity service accounts
7. **IAP Tunnel Users**: Users with IAP tunnel access

### Service Perimeters

1. **Main Perimeter**: Comprehensive perimeter covering all core services
2. **Bridge Perimeter**: Allows communication between perimeters for specific services
3. **VPC SC Perimeter**: Network-specific controls for VPC services

## Usage

```hcl
module "vpc_sc" {
  source = "../modules/terraform-google-vpc-sc"

  organization_id = "your-org-id"
  host_project_id = "host-project-id"
  gke_project_id  = "gke-project-id"
  data_project_id = "data-project-id"

  # Access level configurations
  devops_team_members = [
    "user:admin@example.com",
    "serviceAccount:admin-sa@project.iam.gserviceaccount.com"
  ]
  
  backend_team_members = [
    "group:backend-team@example.com"
  ]
  
  service_accounts = [
    "serviceAccount:bastion@host-project.iam.gserviceaccount.com",
    "serviceAccount:gke-sa@gke-project.iam.gserviceaccount.com"
  ]
  
  gke_workload_identity_service_accounts = [
    "serviceAccount:gke-project.svc.id.goog[namespace/service-account]"
  ]
  
  iap_tunnel_users = [
    "user:user1@example.com",
    "user:user2@example.com"
  ]

  # Service configurations (optional - uses defaults if not specified)
  restricted_services = [
    "storage.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com"
  ]
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `organization_id` | The organization ID where the VPC SC policy will be created | `string` |
| `host_project_id` | The host project ID for the VPC SC perimeter | `string` |
| `gke_project_id` | The GKE project ID to be included in the VPC SC perimeter | `string` |
| `data_project_id` | The data project ID to be included in the VPC SC perimeter | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `devops_team_members` | List of DevOps team members (users and service accounts) | `list(string)` | `[]` |
| `backend_team_members` | List of backend team members (users and service accounts) | `list(string)` | `[]` |
| `frontend_team_members` | List of frontend team members (users and service accounts) | `list(string)` | `[]` |
| `mobile_team_members` | List of mobile team members (users and service accounts) | `list(string)` | `[]` |
| `service_accounts` | List of service accounts for access control | `list(string)` | `[]` |
| `gke_workload_identity_service_accounts` | List of GKE workload identity service accounts | `list(string)` | `[]` |
| `iap_tunnel_users` | List of IAP tunnel users | `list(string)` | `[]` |
| `restricted_services` | List of restricted services for the main perimeter | `list(string)` | See default list |
| `bridge_services` | List of services for the bridge perimeter | `list(string)` | See default list |
| `vpc_restricted_services` | List of VPC-specific restricted services | `list(string)` | See default list |

## Outputs

| Name | Description |
|------|-------------|
| `access_policy_name` | The name of the created access policy |
| `main_perimeter_name` | The name of the main service perimeter |
| `bridge_perimeter_name` | The name of the bridge service perimeter |
| `vpc_sc_perimeter_name` | The name of the VPC SC service perimeter |

## Security Considerations

1. **Principle of Least Privilege**: Only grant necessary access levels
2. **Service Account Management**: Use workload identity for GKE workloads
3. **Network Segmentation**: Separate concerns with different perimeters
4. **Audit Logging**: All access is logged for compliance and security

## Default Restricted Services

The module includes comprehensive default service lists covering:

- **Compute Services**: Compute Engine, GKE, Cloud Run
- **Data Services**: Cloud SQL, Redis, BigQuery, Pub/Sub
- **Security Services**: Secret Manager, IAM, KMS
- **Networking Services**: VPC, Load Balancing, Cloud Armor
- **Monitoring Services**: Cloud Monitoring, Logging, Trace
- **Development Services**: Cloud Build, Artifact Registry

## Migration from Hardcoded Configuration

This module replaces the previous hardcoded configuration with:

1. **Configurable Access Levels**: All users and service accounts are now variables
2. **Dynamic Resource Creation**: Access levels are only created if members are provided
3. **Flexible Service Lists**: All service lists are configurable
4. **Environment-Specific Configuration**: Easy to adapt for different environments

## Example Configuration for fintech

```hcl
# net-vpcsc/terraform.tfvars
organization_id = "your-org-id"
host_project_id = "host-project"
gke_project_id  = "gke-project"
data_project_id = "data-project"

devops_team_members = [
  "user:user1@fintech.com",
]

service_accounts = [
  "serviceAccount:bastion-prod-host@host-project.iam.gserviceaccount.com",
  "serviceAccount:gke-service-account@gke-project.iam.gserviceaccount.com",
  "serviceAccount:cloudsql-admin@data-project.iam.gserviceaccount.com"
]

gke_workload_identity_service_accounts = [
  "serviceAccount:gke-project.svc.id.goog[backend/backend-sa]",
  "serviceAccount:gke-project.svc.id.goog[frontend/frontend-sa]",
  "serviceAccount:gke-project.svc.id.goog[api/api-sa]",
  "serviceAccount:gke-project.svc.id.goog[workers/workers-sa]",
  "serviceAccount:gke-project.svc.id.goog[monitoring/monitoring-sa]"
]

iap_tunnel_users = [
  "user:user1@fintech.com",
]
```

## Troubleshooting

### Common Issues

1. **Access Denied Errors**: Ensure users/service accounts are included in appropriate access levels
2. **Service Communication Issues**: Check bridge perimeter configuration for inter-service communication
3. **GKE Workload Identity**: Verify service account format: `project.svc.id.goog[namespace/sa-name]`

### Validation

Use the following commands to validate the configuration:

```bash
terraform plan
terraform validate
```

## Dependencies

- Google Cloud Platform project with Access Context Manager API enabled
- Organization-level permissions for creating access policies
- Project-level permissions for the target projects