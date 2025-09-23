# terraform-google-gke

This Terraform module creates and manages Google Kubernetes Engine (GKE) clusters with advanced security, monitoring, and operational features.

## Features

- **🔒 Private Cluster**: Private nodes and endpoints with custom master CIDR
- **🔐 Workload Identity**: Secure pod-to-service authentication with Google Cloud IAM
- **🛡️ Network Security**: Network policy enforcement and master authorized networks
- **📊 Observability**: Comprehensive monitoring, logging, and managed Prometheus
- **📈 Auto-scaling**: Horizontal pod autoscaling and cluster autoscaling
- **🔧 Maintenance**: Configurable maintenance windows (daily/recurring)
- **🛡️ Security Posture**: Built-in vulnerability scanning and security management
- **🏷️ Node Management**: Dynamic node pools with custom taints, labels, and configurations

## Usage

```hcl
module "gke_cluster" {
  source = "../modules/terraform-google-gke"

  # Basic Configuration
  cluster_name = "gke-cluster"
  project_id   = "gke-project"
  region       = "us-central1"

  # Network Configuration
  network                  = "projects/host-project/global/networks/gke-vpc"
  subnetwork              = "projects/host-project/regions/us-central1/subnetworks/gke-subnet"
  master_ipv4_cidr_block  = "10.160.1.0/28"

  # IP Allocation for Pods and Services
  ip_allocation_policy = {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Node Pools Configuration
  node_pools = {
    "app-pool" = {
      initial_node_count  = 1
      min_count           = 3
      max_count           = 9
      machine_type        = "n2d-standard-2"
      disk_size_gb        = 100
      disk_type           = "pd-balanced"
      preemptible         = false
    }
    
    "service-pool" = {
      initial_node_count  = 1
      min_count           = 3
      max_count           = 9
      machine_type        = "n2d-standard-2"
      disk_size_gb        = 100
      disk_type           = "pd-balanced"
      preemptible         = false
    }
  }

  # Security Configuration
  master_authorized_networks = [
    {
      cidr_block   = "10.160.0.0/16"
      display_name = "gke-vpc"
    },
    {
      cidr_block   = "10.161.0.0/16"
      display_name = "data-vpc"
    }
  ]

  # Observability
  monitoring = {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
    managed_prometheus = {
      enabled = true
    }
  }

  logging = {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS", "API_SERVER"]
  }

  # Labels
  llabels = {
  environment = "production"
  project     = "gke-project"
  cost_center = "production"
  owner       = "devops"
  managed_by  = "terraform"
}
}
```

## Resources Created

This module creates the following resources:

- **google_container_cluster**: Primary GKE cluster with private configuration
- **google_container_node_pool**: One or more node pools with autoscaling
- **google_service_account**: Optional service account for cluster nodes

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the GKE cluster | `string` | n/a | yes |
| project_id | The project ID to deploy the cluster | `string` | n/a | yes |
| region | The region to deploy the cluster | `string` | n/a | yes |
| network | The VPC network to deploy the cluster | `string` | n/a | yes |
| subnetwork | The subnetwork to deploy the cluster | `string` | n/a | yes |
| master_ipv4_cidr_block | The IP range for the cluster master | `string` | `"10.60.1.0/28"` | no |
| ip_allocation_policy | Configuration for IP allocation | `object` | `{}` | no |
| node_pools | Map of node pool configurations | `map(object)` | `{}` | no |
| master_authorized_networks | List of authorized networks for API server | `list(object)` | `[]` | no |
| enable_private_nodes | Enable private nodes | `bool` | `true` | no |
| enable_private_endpoint | Enable private endpoint | `bool` | `true` | no |
| enable_network_policy | Enable Kubernetes network policy | `bool` | `true` | no |
| enable_workload_identity | Enable Workload Identity | `bool` | `true` | no |
| enable_shielded_nodes | Enable shielded nodes | `bool` | `true` | no |
| monitoring | Monitoring configuration | `object` | `{}` | no |
| logging | Logging configuration | `object` | `{}` | no |
| maintenance_policy | Maintenance window configuration | `object` | `{}` | no |
| labels | Labels to apply to the cluster | `map(string)` | `{}` | no |

### Node Pool Configuration

Each node pool in the `node_pools` map supports:

```hcl
{
  initial_node_count = number           # Initial number of nodes
  min_count         = number            # Minimum number of nodes (autoscaling)
  max_count         = number            # Maximum number of nodes (autoscaling)
  machine_type      = string            # GCE machine type
  disk_size_gb      = number            # Boot disk size in GB
  disk_type         = string            # Boot disk type (pd-ssd, pd-standard)
  preemptible       = bool              # Use preemptible instances
  spot             = bool               # Use spot instances
  node_labels      = map(string)        # Kubernetes node labels
  node_taints      = list(object)       # Kubernetes node taints
  tags             = list(string)       # Network tags
  service_account  = string             # Service account email
  oauth_scopes     = list(string)       # OAuth scopes for the service account
}
```

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | The name of the GKE cluster |
| cluster_endpoint | The endpoint of the GKE cluster |
| cluster_ca_certificate | The cluster CA certificate |
| cluster_location | The location of the GKE cluster |
| node_pools | Information about the created node pools |
| service_account | The service account used by the cluster nodes |

## Security Features

### Private Cluster

- Private nodes with no external IP addresses
- Private endpoint for cluster API server
- Custom master CIDR block for control plane

### Workload Identity

- Secure authentication between Kubernetes pods and Google Cloud services
- Eliminates need for service account keys in pods
- Fine-grained IAM integration

### Network Security

- Kubernetes network policy enforcement
- Master authorized networks for API server access
- Network tags for firewall rule targeting

### Node Security

- Shielded GKE nodes with secure boot and integrity monitoring
- Container-Optimized OS with automatic security updates
- Workload Identity for secure service authentication

## Best Practices Implemented

1. **No Default Node Pool**: Removes default node pool and creates custom ones for better control
2. **Secure Defaults**: Private cluster, Workload Identity, and network policies enabled by default
3. **Operational Excellence**: Comprehensive monitoring, logging, and maintenance windows
4. **Resource Management**: Proper resource limits, autoscaling, and node affinity
5. **Security Hardening**: Shielded nodes, private endpoints, and authorized networks

## Troubleshooting

### Common Issues

1. **Insufficient IP addresses**: Ensure secondary IP ranges are large enough for pods and services
2. **Master authorized networks**: Add your IP/CIDR to access the private endpoint
3. **Service account permissions**: Ensure the cluster service account has necessary IAM roles
4. **Node pool creation fails**: Check machine type availability in the selected region

### Debugging

```bash
# Get cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION --project=PROJECT_ID

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check cluster info
gcloud container clusters describe CLUSTER_NAME --region=REGION --project=PROJECT_ID
```

## Migration Notes

When upgrading from older versions:

1. **Kubernetes Version**: Check compatibility with your workloads
2. **Node Pool Changes**: May require node pool recreation
3. **Network Policies**: Ensure existing policies are compatible
4. **Workload Identity**: May require service account binding updates

---

**Module Version**: 1.0.0  
**Terraform Version**: >= 1.5  
**Provider Version**: >= 5.0  
**Last Updated**: June 2025