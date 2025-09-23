# terraform-google-memorystore

This Terraform module creates and manages Google Cloud Memorystore Redis instances with advanced security, high availability, and operational features for production environments.

## Features

- **🔒 Private Network**: Private IP configuration with VPC network integration
- **🛡️ Security**: TLS encryption, authentication, and authorized networks
- **💾 Persistence**: Configurable RDB snapshots for data durability
- **📊 High Availability**: STANDARD_HA tier with automatic failover
- **🔧 Maintenance**: Configurable maintenance windows
- **🏷️ Resource Management**: User labels and comprehensive monitoring
- **🔐 Authentication**: OSS Redis AUTH support
- **📈 Scalability**: Read replicas and configurable memory sizes

## Usage

```hcl
module "redis_instance" {
  source = "../modules/terraform-google-memorystore"

  # Basic Configuration
  project_id      = "data-project-mnch"
  instance_name   = "redis"
  region          = "us-central1"

  # Instance Configuration
  tier            = "STANDARD_HA"
  memory_size_gb  = 5
  redis_version   = "REDIS_7_0"

  # Network Configuration
  authorized_network = "projects/host-project/global/networks/data-vpc"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # Security Configuration
  auth_enabled             = true
  transit_encryption_mode  = "SERVER_AUTHENTICATION"

  # Maintenance Window
  maintenance_window = {
    day    = 7  # Sunday
    hour   = 2  # 2 AM
    minute = 0
  }

  # Persistence Configuration
  persistence_config = {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWELVE_HOURS"
  }

  # Redis Configuration
  redis_configs = {
    maxmemory-policy = "allkeys-lru"
    timeout          = "300"
    tcp-keepalive    = "300"
  }

  # High Availability
  replica_count       = 1
  read_replicas_mode  = "READ_REPLICAS_ENABLED"

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

- **google_redis_instance**: Memorystore Redis instance with comprehensive configuration

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
| instance_name | The name of the Memorystore Redis instance | `string` | n/a | yes |
| tier | The service tier of the instance | `string` | `"STANDARD_HA"` | no |
| memory_size_gb | Redis memory size in GB | `number` | `1` | no |
| region | The region to deploy to | `string` | n/a | yes |
| redis_version | The version of Redis software | `string` | `"REDIS_7_0"` | no |
| authorized_network | The full name of the network that should be peered with Google Cloud | `string` | `null` | no |
| connect_mode | The connection mode of the Redis instance | `string` | `"PRIVATE_SERVICE_ACCESS"` | no |
| auth_enabled | Indicates whether OSS Redis AUTH is enabled for the instance | `bool` | `true` | no |
| transit_encryption_mode | The TLS encryption mode for the Redis instance | `string` | `"SERVER_AUTHENTICATION"` | no |
| maintenance_window | Maintenance window configuration | `object` | `{}` | no |
| user_labels | User labels to apply to the instance | `map(string)` | `{}` | no |
| redis_configs | Redis configuration parameters | `map(string)` | `{}` | no |
| replica_count | The number of replica nodes | `number` | `1` | no |
| read_replicas_mode | Read replicas mode | `string` | `"READ_REPLICAS_ENABLED"` | no |
| customer_managed_key | The KMS key reference that you provisioned for this instance | `string` | `null` | no |
| persistence_config | Persistence configuration | `object` | `{}` | no |

### Maintenance Window Configuration

```hcl
maintenance_window = {
  day    = number  # Day of week (1-7, where 1 is Monday)
  hour   = number  # Hour of day (0-23)
  minute = number  # Minute of hour (0-59)
}
```

### Persistence Configuration

```hcl
persistence_config = {
  persistence_mode        = string  # "DISABLED" or "RDB"
  rdb_snapshot_period     = string  # Snapshot period (e.g., "ONE_HOUR", "SIX_HOURS", "TWELVE_HOURS", "TWENTY_FOUR_HOURS")
  rdb_snapshot_start_time = string  # Optional start time for snapshots
}
```

### Redis Configuration Parameters

```hcl
redis_configs = {
  maxmemory-policy = string  # Memory eviction policy
  timeout          = string  # Client timeout in seconds
  tcp-keepalive    = string  # TCP keepalive in seconds
  # Add other Redis configuration parameters as needed
}
```

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the Memorystore Redis instance |
| instance_id | The ID of the Memorystore Redis instance |
| current_location_id | The current zone where the Redis endpoint is placed |
| host | The IP address of the instance |
| port | The port number of the instance |
| redis_configs | The Redis configuration parameters |
| auth_string | The AUTH string for the Redis instance (sensitive) |
| server_ca_certs | List of server CA certificates for the instance |
| persistence_iam_identity | The Cloud IAM identity associated with this instance |
| tier | The service tier of the instance |
| memory_size_gb | Redis memory size in GB |
| redis_version | The version of Redis software |
| connect_mode | The connection mode of the Redis instance |
| auth_enabled | Indicates whether OSS Redis AUTH is enabled for the instance |
| transit_encryption_mode | The TLS encryption mode for the Redis instance |
| replica_count | The number of replica nodes |
| read_replicas_mode | Read replicas mode |
| maintenance_policy | Maintenance policy information |
| persistence_config | Persistence configuration information |
| labels | Resource labels |
| connection_string | Redis connection string (host:port) |

## Security Considerations

- **Private Network**: Always use `PRIVATE_SERVICE_ACCESS` connect mode for production
- **Authentication**: Enable `auth_enabled` for secure access
- **Encryption**: Use `SERVER_AUTHENTICATION` transit encryption mode
- **Authorized Networks**: Configure `authorized_network` to restrict access to your VPC
- **Labels**: Apply appropriate labels for cost tracking and resource management

## High Availability

- **STANDARD_HA Tier**: Provides automatic failover and high availability
- **Read Replicas**: Configure `replica_count` for additional read capacity
- **Persistence**: Enable RDB snapshots for data durability

## Maintenance

- **Maintenance Windows**: Configure maintenance windows during low-traffic periods
- **Redis Version**: Keep Redis version updated for security and performance
- **Configuration**: Use `redis_configs` to optimize Redis performance

## Examples

### Basic Redis Instance

```hcl
module "basic_redis" {
  source = "../modules/terraform-google-memorystore"

  project_id     = "my-project"
  instance_name  = "basic-redis"
  region         = "us-central1"
  memory_size_gb = 1
  tier           = "BASIC"
}
```

### Production Redis Instance

```hcl
module "production_redis" {
  source = "../modules/terraform-google-memorystore"

  project_id     = "my-project"
  instance_name  = "production-redis"
  region         = "us-central1"
  memory_size_gb = 10
  tier           = "STANDARD_HA"

  authorized_network = "projects/host-project/global/networks/my-vpc"
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  auth_enabled       = true

  persistence_config = {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWELVE_HOURS"
  }

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
    timeout          = "300"
  }

  user_labels = {
    environment = "production"
    team        = "platform"
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. 