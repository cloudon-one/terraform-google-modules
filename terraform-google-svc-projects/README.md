# terraform-google-svc-projects

This Terraform module creates and manages Google Cloud projects in a multi-project architecture with proper API enablement and service account management.

## Features

- **🏗️ Multi-Project Architecture**: Creates host project and specialized service projects
- **🔌 API Management**: Automatically enables required APIs for each project type
- **💳 Billing Integration**: Associates projects with billing accounts
- **📁 Folder Organization**: Places projects in organizational folders with proper hierarchy
- **🔐 Service Account Management**: Retrieves default compute service accounts for integration
- **🏷️ Consistent Labeling**: Applies standardized labels across all projects
- **🎲 Unique Naming**: Uses random suffixes to ensure globally unique project IDs

## Usage

```hcl
module "service_projects" {
  source = "../modules/terraform-google-svc-projects"

  # Basic Configuration
  suffix            = "a1b2"  # Random 4-character suffix
  billing_account_id = "01234-567890-ABCD"
  folder_id         = "1234567890"

  # Project Names (will have suffix appended)
  host_project_name = "host-project"
  gke_project_name  = "gke-project"
  data_project_name = "data-project"

  # Labels
  labels = {
    environment = "production"
    team        = "devops"
    cost_center = "devops"
    owner       = "devops"
  }
}
```

## Projects Created

This module creates three specialized projects:

### 1. Host Project (Shared VPC Host)

**Project ID**: `{host_project_name}-{suffix}`  
**Purpose**: Hosts shared VPC networks and provides centralized networking

**APIs Enabled**

- `compute.googleapis.com` - Compute Engine for VPC and networking
- `container.googleapis.com` - GKE for container orchestration
- `dns.googleapis.com` - Cloud DNS for private DNS zones
- `servicenetworking.googleapis.com` - Service networking for VPC peering
- `cloudresourcemanager.googleapis.com` - Resource management

**Configuration**

- `auto_create_network = false` - Prevents default VPC creation
- Shared VPC host project enabled

### 2. GKE Service Project

**Project ID**: `{gke_project_name}-{suffix}`  
**Purpose**: Runs Google Kubernetes Engine workloads and applications

**APIs Enabled**

- `compute.googleapis.com` - Compute resources for GKE nodes
- `container.googleapis.com` - GKE cluster management
- `logging.googleapis.com` - Cloud Logging for observability
- `monitoring.googleapis.com` - Cloud Monitoring for metrics
- `clouddebugger.googleapis.com` - Cloud Debugger for troubleshooting
- `cloudtrace.googleapis.com` - Cloud Trace for performance analysis

**Configuration**

- `auto_create_network = true` - Default VPC (will be removed by Shared VPC)
- Service project attached to host project VPC

### 3. Data Service Project

**Project ID**: `{data_project_name}-{suffix}`  
**Purpose**: Runs data processing, analytics, and storage workloads

**APIs Enabled**

- `compute.googleapis.com` - Compute resources for data processing
- `bigquery.googleapis.com` - BigQuery for analytics
- `storage.googleapis.com` - Cloud Storage for data lakes
- `dataflow.googleapis.com` - Dataflow for stream/batch processing
- `dataproc.googleapis.com` - Dataproc for Spark/Hadoop workloads
- `composer.googleapis.com` - Cloud Composer for workflow orchestration
- `pubsub.googleapis.com` - Pub/Sub for messaging
- `sqladmin.googleapis.com` - Cloud SQL for managed databases
- `sql-component.googleapis.com` - SQL component services

**Configuration**

- `auto_create_network = true` - Default VPC (will be removed by Shared VPC)
- Service project attached to host project VPC

## Resources Created

This module creates the following resources:

- **google_project** (×3): Host project and two service projects
- **google_project_service** (×19): API enablement across all projects
- **data.google_compute_default_service_account** (×2): Default service accounts for service projects

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| google | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 5.0 |
| random | >= 3.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| suffix | Random suffix for unique project IDs | `string` | n/a | yes |
| billing_account_id | The billing account ID to associate with projects | `string` | n/a | yes |
| folder_id | The folder ID where projects will be created | `string` | n/a | yes |
| host_project_name | Name of the host project (without suffix) | `string` | `"host-project"` | no |
| gke_project_name | Name of the GKE service project (without suffix) | `string` | `"gke-project"` | no |
| data_project_name | Name of the data service project (without suffix) | `string` | `"data-project"` | no |
| labels | Labels to apply to all projects | `map(string)` | `{}` | no |
| host_project_apis | APIs to enable in the host project | `list(string)` | `[default_apis]` | no |
| gke_project_apis | APIs to enable in the GKE project | `list(string)` | `[default_apis]` | no |
| data_project_apis | APIs to enable in the data project | `list(string)` | `[default_apis]` | no |

### Default API Lists

**Host Project APIs**:
```hcl
[
  "compute.googleapis.com",
  "container.googleapis.com", 
  "dns.googleapis.com",
  "servicenetworking.googleapis.com",
  "cloudresourcemanager.googleapis.com"
]
```

**GKE Project APIs**:
```hcl
[
  "compute.googleapis.com",
  "container.googleapis.com",
  "logging.googleapis.com", 
  "monitoring.googleapis.com",
  "clouddebugger.googleapis.com",
  "cloudtrace.googleapis.com"
]
```

**Data Project APIs**:
```hcl
[
  "compute.googleapis.com",
  "bigquery.googleapis.com",
  "storage.googleapis.com",
  "dataflow.googleapis.com", 
  "dataproc.googleapis.com",
  "composer.googleapis.com",
  "pubsub.googleapis.com",
  "sqladmin.googleapis.com",
  "sql-component.googleapis.com"
]
```

## Outputs

| Name | Description |
|------|-------------|
| host_project | Host project details (id, name, number) |
| gke_project | GKE project details (id, name, number, default_service_account) |
| data_project | Data project details (id, name, number, default_service_account) |
| host_project_id | ID of the host project |
| gke_project_id | ID of the GKE service project |
| gke_project_number | Project number of the GKE service project |
| data_project_id | ID of the data service project |
| data_project_number | Project number of the data service project |

### Output Example

```hcl
host_project = {
  project_id = "host-project"
  name       = "host-project"
  number     = "1234567890"
}

gke_project = {
  project_id              = "gke-project"
  name                    = "gke-project"
  number                  = "1234567890"
  default_service_account = "1234567890-compute@developer.gserviceaccount.com"
}

data_project = {
  project_id              = "data-project"
  name                    = "data-project"
  number                  = "1234567890"
  default_service_account = "1234567890-compute@developer.gserviceaccount.com"
}
```

## Prerequisites

### Required Permissions

The user or service account running Terraform must have:

1. **Billing Account Permissions**:
   - `roles/billing.projectManager` on the billing account
   - Permission: `billing.resourceAssociations.create`

2. **Folder Permissions**:
   - `roles/resourcemanager.projectCreator` on the folder
   - `roles/resourcemanager.projectIamAdmin` on the folder

3. **Organization Permissions** (if applicable):
   - `roles/serviceusage.serviceUsageAdmin` for API enablement

### Billing Account Format

The billing account ID must be in the format: `XXXXXX-XXXXXX-XXXXXX`

Example: `0123451-678901-ABCDEF`

## Example Configurations

### Basic Configuration
```hcl
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "service_projects" {
  source = "../modules/terraform-google-svc-projects"

  suffix             = random_string.suffix.result
  billing_account_id = "0123451-678901-ABCDEF"
  folder_id          = "1234567890"
  
  labels = {
    environment = "production"
    team        = "devops"
  }
}
```

### Custom Project Names

```hcl
module "custom_projects" {
  source = "../modules/terraform-google-svc-projects"

  suffix             = "dev1"
  billing_account_id = "0123451-678901-ABCDEF"
  folder_id          = "folders/dev-folder"
  
  host_project_name = "host-project"
  gke_project_name  = "gke-project"
  data_project_name = "data-project"
  
  labels = {
    environment = "production"
    team        = "fintech-devops"
    cost_center = "fintech-devops"
  }
}
```

### Additional APIs

```hcl
module "extended_projects" {
  source = "../modules/terraform-google-svc-projects"

  suffix             = random_string.suffix.result
  billing_account_id = var.billing_account_id
  folder_id          = var.folder_id
  gke_project_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "clouddebugger.googleapis.com",
    "cloudtrace.googleapis.com",
    "artifactregistry.googleapis.com",  
    "secretmanager.googleapis.com"      
  ]
  
  data_project_apis = [
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "dataflow.googleapis.com",
    "dataproc.googleapis.com",
    "composer.googleapis.com",
    "pubsub.googleapis.com",
    "sqladmin.googleapis.com",
    "sql-component.googleapis.com",
    "aiplatform.googleapis.com",       
    "notebooks.googleapis.com"         
  ]
}
```

## Integration with Other Modules

This module is typically used as the foundation for other infrastructure modules:

```hcl
# Create projects first
module "projects" {
  source = "../modules/terraform-google-svc-projects"
  # ... configuration
}

# Then create networking
module "network" {
  source = "../modules/terraform-google-svpc"
  
  project_id = module.projects.host_project_id
  # ... other configuration
}

# Then create GKE cluster
module "gke" {
  source = "../modules/terraform-google-gke"
  
  project_id = module.projects.gke_project_id
  network    = module.network.vpc_self_link
  subnetwork = module.network.subnets["gke"].self_link
  # ... other configuration
}
```

## Troubleshooting

### Common Issues

1. **Billing Account Permissions**
   ```
   Error: failed pre-requisites: missing permission on "billingAccounts/..."
   ```
   **Solution**: Grant `roles/billing.projectManager` on the billing account

2. **Folder Permissions**
   ```
   Error: Error creating project: Permission denied
   ```
   **Solution**: Grant `roles/resourcemanager.projectCreator` on the folder

3. **API Enablement Failures**
   ```
   Error: Error enabling service: Service Usage API not enabled
   ```
   **Solution**: Enable Service Usage API manually or grant `roles/serviceusage.serviceUsageAdmin`

4. **Project ID Already Exists**
   ```
   Error: Project ID already exists
   ```
   **Solution**: Use a different suffix or project name

### Debugging

```bash
gcloud beta billing accounts get-iam-policy BILLING_ACCOUNT_ID
gcloud resource-manager folders get-iam-policy FOLDER_ID
gcloud projects list --filter="parent.id:FOLDER_ID"
gcloud services list --enabled --project=PROJECT_ID
```

## Best Practices

1. **Random Suffixes**: Always use random suffixes to avoid naming conflicts
2. **Minimal APIs**: Only enable APIs that are actually needed
3. **Consistent Labels**: Use consistent labeling across all projects
4. **Folder Organization**: Organize projects in appropriate folders
5. **Billing Monitoring**: Set up billing alerts and budgets
6. **Project Lifecycle**: Plan for project deletion and data retention

## Migration Notes

When migrating existing projects:

1. **API Compatibility**: Ensure all required APIs are enabled
2. **Service Account**: Update references to default service accounts
3. **IAM Bindings**: May need to recreate IAM bindings
4. **Resource Dependencies**: Update dependent resources with new project IDs

---

**Module Version**: 1.5.0  
**Terraform Version**: >= 1.5  
**Provider Version**: >= 5.0  
**Last Updated**: June 2025