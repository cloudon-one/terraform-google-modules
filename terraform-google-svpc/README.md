# terraform-google-svpc

This Terraform module creates and manages comprehensive Google Cloud Shared VPC infrastructure, including VPC networks, subnets, Cloud NAT, firewall rules, VPC peering, and private DNS management.

## Features

- **🌐 VPC Network Management**: Custom VPC with configurable routing mode and MTU
- **🏗️ Subnet Management**: Multiple subnets with secondary IP ranges for GKE pods and services
- **🌍 Cloud NAT**: Outbound internet access for private resources with logging
- **🔥 Firewall Management**: Comprehensive ingress/egress rules with logging support
- **🔗 VPC Peering**: Cross-VPC connectivity with custom route management
- **🤝 Shared VPC**: Host-service project networking model for multi-project architectures
- **🌐 Private DNS**: Internal DNS zones and records for service discovery
- **📊 Flow Logging**: VPC flow logs for network monitoring and troubleshooting
- **🏷️ Resource Labeling**: Consistent labeling across all network resources

## Usage

```hcl
module "shared_vpc" {
  source = "../modules/terraform-google-svpc"

  # Basic Configuration
  project_id = "host-project"
  vpc_name   = "gke-vpc"

  # Network Configuration
  routing_mode = "GLOBAL"
  mtu          = 1460

  # Subnets with Secondary Ranges
  subnets = {
    gke = {
      name                     = "gke-subnet"
      ip_cidr_range            = "10.160.4.0/22"
      region                   = "us-central1"
      purpose                  = null
      role                     = null
      private_ip_google_access = true
      
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.160.128.0/17"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.160.8.0/22"
        }
      ]
      
      log_config = {
        aggregation_interval = "INTERVAL_10_MIN"
        flow_sampling        = 0.5
        metadata            = "INCLUDE_ALL_METADATA"
      }
    }
    
    proxy = {
      name                     = "gke-proxy-subnet"
      ip_cidr_range           = "10.160.0.0/24"
      region                  = "us-central1"
      purpose                 = "INTERNAL_HTTPS_LOAD_BALANCER"
      role                    = "ACTIVE"
      private_ip_google_access = true
      secondary_ip_ranges     = []
      log_config              = null
    }
  }

  # Cloud NAT Configuration
  cloud_nat_config = {
    router_name                        = "router"
    router_region                      = "us-central1"
    router_asn                         = 64514
    nat_name                           = "gke-nat"
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    log_config = {
      enable = true
      filter = "ERRORS_ONLY"
    }
  }

  # Firewall Rules
  firewall_rules = {
    allow-internal = {
      name          = "allow-internal-traffic"
      description   = "Allow internal communication between subnets"
      direction     = "INGRESS"
      disabled      = false
      enable_logging = true
      priority      = 1000
      source_ranges = ["10.160.0.0/16"]
      target_tags   = []
      
      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
      deny = []
    }
    
    allow-iap = {
      name          = "allow-iap-access"
      description   = "Allow Google Cloud Identity-Aware Proxy"
      direction     = "INGRESS"
      disabled      = false
      enable_logging = true
      priority      = 1000
      source_ranges = ["35.235.240.0/20"]
      target_tags   = ["iap-access"]
      
      allow = [
        {
          protocol = "tcp"
          ports    = ["22", "3389"]
        }
      ]
      deny = []
    }
  }

  # VPC Peering Configuration
  vpc_peering_config = {
    to-data-vpc = {
      name                 = "gke-to-data-peering"
      peer_network         = "projects/host-project/global/networks/data-vpc"
      auto_create_routes   = true
      export_custom_routes = true
      import_custom_routes = true
    }
  }

  # Shared VPC Configuration
  enable_shared_vpc = true
  service_projects = {
    gke  = "gke-project"
    data = "data-project"
  }

  # Private DNS Configuration
  dns_config = {
    internal-zone = {
      name        = "internal"
      dns_name    = "prod.internal."
      description = "Internal DNS zone for production services"
      networks = [
        "projects/host-project/global/networks/production-vpc"
      ]
    }
  }

  dns_records = {
    api = {
      name     = "api.prod.internal."
      zone_key = "internal"
      type     = "A"
      ttl      = 300
      rrdatas  = ["10.160.4.10"]
    }
    
    database = {
      name     = "db.prod.internal."
      zone_key = "internal"
      type     = "A"
      ttl      = 300
      rrdatas  = ["10.160.4.20"]
    }
  }

  # Resource Labels
  labels = {
    environment = "production"
    team        = "devops"
    managed_by  = "terraform"
  }
}
```

## Resources Created

This module creates the following resources:

- **google_compute_network**: Main VPC network with custom configuration
- **google_compute_subnetwork**: Subnets with secondary IP ranges and flow logging
- **google_compute_router**: Cloud Router for NAT gateway functionality
- **google_compute_router_nat**: Cloud NAT for outbound internet access
- **google_compute_firewall**: Firewall rules with logging support
- **google_compute_network_peering**: VPC peering connections
- **google_compute_shared_vpc_host_project**: Shared VPC host configuration
- **google_compute_shared_vpc_service_project**: Service project attachments
- **google_dns_managed_zone**: Private DNS zones
- **google_dns_record_set**: DNS records for service discovery

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
| project_id | The project ID to deploy the VPC | `string` | n/a | yes |
| vpc_name | The name of the VPC network | `string` | n/a | yes |
| auto_create_subnetworks | Create subnets automatically | `bool` | `false` | no |
| routing_mode | Network routing mode (REGIONAL or GLOBAL) | `string` | `"GLOBAL"` | no |
| mtu | Maximum Transmission Unit for the network | `number` | `1460` | no |
| subnets | Map of subnet configurations | `map(object)` | `{}` | no |
| cloud_nat_config | Cloud NAT configuration | `object` | `null` | no |
| firewall_rules | Map of firewall rule configurations | `map(object)` | `{}` | no |
| vpc_peering_config | Map of VPC peering configurations | `map(object)` | `{}` | no |
| enable_shared_vpc | Enable Shared VPC functionality | `bool` | `false` | no |
| service_projects | Map of service projects to attach | `map(string)` | `{}` | no |
| dns_config | Map of DNS zone configurations | `map(object)` | `{}` | no |
| dns_records | Map of DNS record configurations | `map(object)` | `{}` | no |
| zone_name | Name for the DNS zone (legacy) | `string` | `""` | no |
| dns_name | DNS name for the zone (legacy) | `string` | `""` | no |
| gke_vpc_self_link | Self link of GKE VPC for peering | `string` | `""` | no |
| data_vpc_self_link | Self link of Data VPC for peering | `string` | `""` | no |
| labels | Labels to apply to all resources | `map(string)` | `{}` | no |
| timeouts | Custom timeout options | `object` | `null` | no |

### Subnet Configuration

Each subnet in the `subnets` map supports:

```hcl
{
  name                     = string           # Subnet name
  ip_cidr_range            = string           # Primary CIDR block
  region                   = string           # GCP region
  purpose                  = string           # Subnet purpose (null, INTERNAL_HTTPS_LOAD_BALANCER, etc.)
  role                     = string           # Subnet role (null, ACTIVE, BACKUP)
  private_ip_google_access = bool             # Enable Private Google Access
  secondary_ip_ranges      = list(object)     # Secondary IP ranges for pods/services
  log_config               = object           # Flow log configuration
}
```

### Secondary IP Ranges

```hcl
{
  range_name    = string    # Name of the secondary range
  ip_cidr_range = string    # CIDR block for the secondary range
}
```

### Flow Log Configuration

```hcl
{
  aggregation_interval = string    # INTERVAL_5_SEC, INTERVAL_30_SEC, INTERVAL_1_MIN, INTERVAL_5_MIN, INTERVAL_10_MIN, INTERVAL_15_MIN
  flow_sampling        = number    # Sampling rate (0.0 to 1.0)
  metadata             = string    # INCLUDE_ALL_METADATA, EXCLUDE_ALL_METADATA, CUSTOM_METADATA
}
```

### Cloud NAT Configuration

```hcl
{
  router_name                        = string    # Cloud Router name
  router_region                      = string    # Router region
  router_asn                         = number    # BGP ASN
  nat_name                           = string    # NAT gateway name
  nat_ip_allocate_option             = string    # AUTO_ONLY, MANUAL_ONLY
  source_subnetwork_ip_ranges_to_nat = string    # ALL_SUBNETWORKS_ALL_IP_RANGES, etc.
  log_config = object({
    enable = bool      # Enable NAT logging
    filter = string    # ERRORS_ONLY, TRANSLATIONS_ONLY, ALL
  })
}
```

### Firewall Rule Configuration

```hcl
{
  name                    = string         # Rule name
  description             = string         # Rule description
  direction               = string         # INGRESS or EGRESS
  disabled                = bool           # Whether rule is disabled
  enable_logging          = bool           # Enable firewall logging
  priority                = number         # Rule priority (0-65534)
  source_ranges           = list(string)   # Source CIDR blocks (ingress)
  destination_ranges      = list(string)   # Destination CIDR blocks (egress)
  source_tags             = list(string)   # Source network tags
  target_tags             = list(string)   # Target network tags
  source_service_accounts = list(string)   # Source service accounts
  target_service_accounts = list(string)   # Target service accounts
  
  allow = list(object({
    protocol = string         # tcp, udp, icmp, esp, ah, sctp
    ports    = list(string)   # Port ranges (e.g., ["80", "443", "8080-8090"])
  }))
  
  deny = list(object({
    protocol = string         # tcp, udp, icmp, esp, ah, sctp
    ports    = list(string)   # Port ranges
  }))
}
```

### VPC Peering Configuration

```hcl
{
  name                 = string    # Peering connection name
  peer_network         = string    # Peer network self-link
  auto_create_routes   = bool      # Automatically create routes
  export_custom_routes = bool      # Export custom routes
  import_custom_routes = bool      # Import custom routes
}
```

### DNS Zone Configuration

```hcl
{
  name        = string         # DNS zone name
  dns_name    = string         # DNS domain name (must end with .)
  description = string         # Zone description
  networks    = list(string)   # VPC networks that can query this zone
}
```

### DNS Record Configuration

```hcl
{
  name     = string         # Record name (FQDN, must end with .)
  zone_key = string         # Key of the DNS zone in dns_config
  type     = string         # Record type (A, AAAA, CNAME, MX, etc.)
  ttl      = number         # Time to live in seconds
  rrdatas  = list(string)   # Record data
}
```

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC network |
| vpc_self_link | The self link of the VPC network |
| subnets | Map of subnet details with IDs, self-links, and configurations |
| cloud_nat | Cloud NAT details including ID and name |
| firewall_rules | Map of firewall rule details with IDs and self-links |
| vpc_peering | Map of VPC peering details with IDs and configurations |
| shared_vpc | Shared VPC details including host project and service projects |
| dns_zones | Map of DNS zone details with IDs and name servers |
| dns_records | Map of DNS record details with IDs |
| dns_zone_names | Names of the private DNS zones |
| dns_zone_dns_names | DNS names of the private zones |
| dns_zone_ids | IDs of the private DNS zones |

## Example Configurations

### Basic VPC with Single Subnet
```hcl
module "simple_vpc" {
  source = "../modules/terraform-google-svpc"

  project_id = "host-project"
  vpc_name   = "gke-vpc"

  subnets = {
    
  gke_subnet = {
    name          = "gke-subnet"
    ip_cidr_range = "10.160.4.0/22"
    secondary_ip_ranges = [
      {
        range_name    = "pods"
        ip_cidr_range = "10.160.128.0/17"
      },
      {
        range_name    = "services"
        ip_cidr_range = "10.160.8.0/22"
      }
    ]
    private_ip_google_access = true
    log_config = {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling        = 0.5
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }
}
```

### GKE-Ready VPC with Secondary Ranges
```hcl
module "gke_vpc" {
  source = "../modules/terraform-google-svpc"

  project_id = "host-project"
  vpc_name   = "gke-vpc"

  subnets = {
    gke = {
      name          = "gke-nodes"
      ip_cidr_range = "10.160.0.0/24"
      region        = "us-central1"
      private_ip_google_access = true
      
      secondary_ip_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.160.128.0/17"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.160.8.0/22"
        }
      ]
      
      log_config = {
        aggregation_interval = "INTERVAL_5_MIN"
        flow_sampling        = 0.5
        metadata            = "INCLUDE_ALL_METADATA"
      }
    }
  }

  cloud_nat_config = {
    router_name    = "gke-router"
    router_region  = "us-central1"
    router_asn     = 64514
    nat_name       = "gke-nat"
    nat_ip_allocate_option = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    log_config = {
      enable = true
      filter = "ERRORS_ONLY"
    }
  }
}
```

### Shared VPC with Service Projects
```hcl
module "shared_vpc" {
  source = "../modules/terraform-google-svpc"

  project_id = "host-project"
  vpc_name   = "data-vpc"

  subnets = {
    shared = {
      name          = "data-subnet"
      ip_cidr_range = "10.161.4.0/22"
      region        = "us-central1"
      private_ip_google_access = true
      secondary_ip_ranges = []
      log_config = null
    }
  }

  enable_shared_vpc = true
  service_projects = {
    host_project_name = "host-project"
    gke_project_name  = "gke-project"
    data_project_name = "data-project"

  }

  dns_config = {
    internal = {
      name        = "internal"
      dns_name    = "prod.internal."
      description = "Internal DNS for shared services"
      networks = [
        "projects/host-project/global/networks/data-vpc"
      ]
    }
  }

  dns_records = {
    app1 = {
      name     = "app.prod.internal."
      zone_key = "internal"
      type     = "A"
      ttl      = 300
      rrdatas  = ["10.161.1.10"]
    }
  }
}
```

## Best Practices Implemented

1. **Security First**: Private Google Access enabled by default
2. **Observability**: Flow logging and firewall logging support
3. **Scalability**: Support for multiple subnets and regions
4. **Flexibility**: Configurable MTU, routing mode, and timeouts
5. **Integration**: Ready for GKE with secondary IP ranges
6. **Management**: Consistent labeling and resource organization

## Integration with GKE

This module is designed to work seamlessly with GKE:

```hcl
# Create VPC with GKE-compatible configuration
module "vpc" {
  source = "../modules/terraform-google-svpc"
  
  # ... VPC configuration with secondary ranges
}

# Use VPC in GKE module
module "gke" {
  source = "../modules/terraform-google-gke"
  
  network    = module.vpc.vpc_self_link
  subnetwork = module.vpc.subnets["gke"].self_link
  
  ip_allocation_policy = {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
}
```

## Troubleshooting

### Common Issues

1. **Secondary Range Conflicts**
   ```
   Error: IP range conflicts with existing allocation
   ```
   **Solution**: Ensure secondary IP ranges don't overlap with existing allocations

2. **NAT Router Region Mismatch**
   ```
   Error: Router and NAT must be in the same region
   ```
   **Solution**: Ensure `router_region` matches subnet regions

3. **Shared VPC Permission Issues**
   ```
   Error: Permission denied for Shared VPC operations
   ```
   **Solution**: Grant `roles/compute.xpnAdmin` to the service account

4. **DNS Zone Network References**
   ```
   Error: Invalid network reference in DNS zone
   ```
   **Solution**: Use full network self-links in DNS zone configuration

### Debugging

```bash
# Check VPC configuration
gcloud compute networks describe VPC_NAME --project=PROJECT_ID

# Check subnets
gcloud compute networks subnets list --network=VPC_NAME --project=PROJECT_ID

# Check firewall rules
gcloud compute firewall-rules list --filter="network:VPC_NAME" --project=PROJECT_ID

# Check NAT configuration
gcloud compute routers describe ROUTER_NAME --region=REGION --project=PROJECT_ID

# Check VPC peering
gcloud compute networks peerings list --network=VPC_NAME --project=PROJECT_ID
```

## Migration Notes

When migrating from older versions:
1. **Flow Logging**: New log_config format may require updates
2. **Firewall Rules**: enable_logging parameter deprecated in favor of log_config
3. **VPC Peering**: Additional route control options available
4. **DNS Configuration**: Enhanced DNS record management

---

**Module Version**: 1.0.0  
**Terraform Version**: >= 1.5.0  
**Provider Version**: >= 5.0  
**Last Updated**: June 2025