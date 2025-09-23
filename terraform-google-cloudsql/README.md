# terraform-google-cloudsql

This Terraform module creates and manages Google Cloud SQL instances with advanced security, backup, monitoring, and operational features for production environments.

## Features

- **🔒 Private Network**: Private IP configuration with VPC network integration
- **🛡️ Security**: SSL enforcement, authorized networks, and deletion protection
- **💾 Backup & Recovery**: Automated backups with point-in-time recovery
- **📊 Monitoring**: Query insights and comprehensive monitoring
- **🔄 High Availability**: Regional deployment with automatic failover
- **📈 Read Replicas**: Scalable read replicas across regions
- **🔧 Maintenance**: Configurable maintenance windows
- **🏷️ Resource Management**: User labels and database/user management

## Usage

```hcl
module "cloudsql_instance" {
  source = "../modules/terraform-google-cloudsql"

  # Basic Configuration
  project_id      = "data-project-mnch"
  instance_name   = "-<service>"
  database_version = "POSTGRES_15"
  region          = "us-central1"

  # Instance Configuration
  machine_type       = "db-n1-standard-4"
  disk_type          = "PD_SSD"
  disk_size          = 200
  availability_type  = "REGIONAL"
  primary_zone       = "us-central1-a"

  # Network Configuration
  ip_configuration = {
    ipv4_enabled    = false
    private_network = "projects/host-project-8hhr/global/networks/data-vpc"
    require_ssl     = true
    authorized_networks = [
      {
        name  = "gke-cluster"
        value = "10.160.0.0/16"
      },
      {
        name  = "data-vpc"
        value = "10.161.0.0/16"
      }
    ]
  }

  # Backup Configuration
  backup_configuration = {
    enabled                        = true
    start_time                     = "02:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 7
  }

  # Maintenance Window
  maintenance_window = {
    day          = 7  # Sunday
    hour         = 2  # 2 AM
    update_track = "stable"
  }

  # Database Flags
  database_flags = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "1073741824"  # 1GB
    }
  ]

  # Databases
  databases = {
    app_db = {
      name      = "fintech_app"
      charset   = "utf8mb4"
      collation = "utf8mb4_unicode_ci"
    }
    analytics_db = {
      name      = "fintech_analytics"
      charset   = "utf8mb4"
      collation = "utf8mb4_unicode_ci"
    }
  }

  # Users
  users = {
    app_user = {
      name     = "app_user"
      host     = "%"
      password = "secure_password_here"
    }
    readonly_user = {
      name     = "readonly_user"
      host     = "%"
      password = "readonly_password_here"
    }
  }

  # Read Replicas
  read_replicas = {
    "replica-1" = {
      region                = "us-west1"
      zone                  = "us-west1-a"
      machine_type          = "db-n1-standard-2"
      disk_type             = "PD_SSD"
      disk_size             = 100
      disk_autoresize       = true
      disk_autoresize_limit = 0
      deletion_protection   = true
      ip_configuration = {
        ipv4_enabled    = false
        private_network = "projects/host-project/global/networks/data-vpc"
        require_ssl     = true
        authorized_networks = []
      }
    }
  }

  # Labels
  user_labels = {
    environment = "production"
    team        = "devops"
    cost_center = "production"
  }
}
```

## Resources Created

This module creates the following resources:

- **google_sql_database_instance**: Primary Cloud SQL instance with comprehensive configuration
- **google_sql_database**: One or more databases within the instance
- **google_sql_user**: One or more database users
- **google_sql_ssl_cert**: Optional SSL certificate for client connections
- **google_sql_database_instance**: Read replicas for scalability

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
| project_id | The project ID to deploy to | `string` | n/a | yes |
| instance_name | The name of the Cloud SQL instance | `string` | n/a | yes |
| database_version | The database version to use | `string` | `"POSTGRES_15"` | no |
| region | The region to deploy to | `string` | n/a | yes |
| machine_type | The machine type to use | `string` | `"db-n1-standard-2"` | no |
| disk_type | The disk type to use | `string` | `"PD_SSD"` | no |
| disk_size | The disk size in GB | `number` | `100` | no |
| availability_type | The availability type (ZONAL or REGIONAL) | `string` | `"ZONAL"` | no |
| primary_zone | The primary zone for the instance | `string` | `null` | no |
| deletion_protection | Whether to enable deletion protection | `bool` | `true` | no |
| backup_configuration | Backup configuration | `object` | `{}` | no |
| maintenance_window | Maintenance window configuration | `object` | `{}` | no |
| ip_configuration | IP configuration | `object` | `{}` | no |
| database_flags | Database flags to set | `list(object)` | `[]` | no |
| insights_config | Query insights configuration | `object` | `{}` | no |
| databases | Map of databases to create | `map(object)` | `{}` | no |
| users | Map of users to create | `map(object)` | `{}` | no |
| read_replicas | Map of read replicas to create | `map(object)` | `{}` | no |
| user_labels | User labels to apply to the instance | `map(string)` | `{}` | no |

### Backup Configuration

```hcl
backup_configuration = {
  enabled                        = bool              # Enable automated backups
  start_time                     = string            # Backup start time (HH:MM)
  point_in_time_recovery_enabled = bool              # Enable point-in-time recovery
  transaction_log_retention_days = number            # Transaction log retention
  retained_backups               = number            # Number of backups to retain
}
```

### IP Configuration

```hcl
ip_configuration = {
  ipv4_enabled    = bool                            # Enable public IP
  private_network = string                          # VPC network for private IP
  require_ssl     = bool                            # Require SSL connections
  authorized_networks = list(object({               # Authorized IP ranges
    name  = string
    value = string
  }))
}
```

### Read Replica Configuration

Each read replica supports:

```hcl
{
  region                    = string                 # Replica region
  zone                      = string                 # Replica zone
  machine_type              = string                 # Replica machine type
  disk_type                 = string                 # Replica disk type
  disk_size                 = number                 # Replica disk size
  disk_autoresize           = bool                   # Enable disk autoresize
  disk_autoresize_limit     = number                 # Disk autoresize limit
  deletion_protection       = bool                   # Enable deletion protection
  ip_configuration = object({                        # Replica IP configuration
    ipv4_enabled    = bool
    private_network = string
    require_ssl     = bool
    authorized_networks = list(object({
      name  = string
      value = string
    }))
  })
}
```

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the Cloud SQL instance |
| instance_id | The ID of the Cloud SQL instance |
| connection_name | The connection name of the Cloud SQL instance |
| first_ip_address | The first IP address of the Cloud SQL instance |
| private_ip_address | The private IP address of the Cloud SQL instance |
| public_ip_address | The public IP address of the Cloud SQL instance |
| self_link | The URI of the Cloud SQL instance |
| service_account_email_address | The service account email address of the Cloud SQL instance |
| databases | Map of created databases |
| users | Map of created users |
| ssl_cert | SSL certificate information |
| read_replicas | Map of read replicas |
| instance_settings | Instance settings information |

## Security Features

### Private Network

- Private IP configuration with VPC network integration
- No public IP exposure (configurable)
- Authorized networks for controlled access

### SSL/TLS Security

- SSL enforcement for all connections
- Optional client SSL certificate generation
- Secure connection strings

### Access Control

- Database-level user management
- Host-based access restrictions
- Authorized network IP ranges

### Data Protection

- Deletion protection to prevent accidental deletion
- Automated backups with configurable retention
- Point-in-time recovery capabilities

## Best Practices Implemented

### High Availability

- Regional deployment with automatic failover
- Multi-zone configuration for disaster recovery
- Read replicas for scalability and performance

### Backup & Recovery

- Automated daily backups with configurable timing
- Point-in-time recovery for data protection
- Transaction log retention for audit trails

### Monitoring & Insights

- Query insights for performance monitoring
- Comprehensive instance metrics
- Database flag optimization

### Operational Excellence

- Configurable maintenance windows
- Resource labeling for cost management
- Timeout configurations for operations

## Database Support

This module supports the following database engines:

- **PostgreSQL**: Versions 9.6, 10, 11, 12, 13, 14, 15, 16
- **SQL Server**: Versions 2017, 2019, 2022

## Cost Optimization

- Configurable machine types and disk sizes
- Disk autoresize with limits
- Read replicas for read-heavy workloads
- Resource labeling for cost tracking

## Examples

### Basic PostgreSQL Instance

```hcl
module "mysql_basic" {
  source = "../modules/terraform-google-cloudsql"

  project_id      = "-data-project"
  instance_name   = "-data-project"
  database_version = "POSTGRES_15"
  region          = "us-central1"
  machine_type    = "db-n1-standard-2"
}
```

### High Availability PostgreSQL

```hcl
module "postgres_ha" {
  source = "../modules/terraform-google-cloudsql"

  project_id       = "-data-project"
  instance_name    = "-data-project">"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  availability_type = "REGIONAL"
  primary_zone     = "uus-central1-a"
  machine_type     = "db-n1-standard-4"
}
```

### Multi-Region Read Replicas

```hcl
module "mysql_with_replicas" {
  source = "../modules/terraform-google-cloudsql"

  project_id      = "-data-project""
  instance_name   = "-<service>""
  database_version = "POSTGRES_15"
  region          = "europe-central"

  read_replicas = {
    "europe-west4" = {
      region = "us-west4"
      zone   = "us-west4-b"
      machine_type = "db-n1-standard-2"
      # ... other configuration
    }
    "europe-west1" = {
      region = "us-west1"
      zone   = "us-west1-a"
      machine_type = "db-n1-standard-2"
      # ... other configuration
    }
  }
}
``` 