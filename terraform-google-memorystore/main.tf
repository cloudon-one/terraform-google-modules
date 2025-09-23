# Create Memorystore Redis instance for caching and session storage
# Configured with high availability, encryption, and persistence
resource "google_redis_instance" "cache" {
  name                    = var.instance_name
  tier                    = var.tier
  memory_size_gb          = var.memory_size_gb
  region                  = var.region
  project                 = var.project_id
  redis_version           = var.redis_version
  authorized_network      = var.authorized_network
  connect_mode            = var.connect_mode
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode
  reserved_ip_range       = var.reserved_ip_range

  # Schedule maintenance window for minimal disruption
  # Updates applied during specified weekly window
  maintenance_policy {
    weekly_maintenance_window {
      day = var.maintenance_window.day
      start_time {
        hours   = var.maintenance_window.hour
        minutes = var.maintenance_window.minute
      }
    }
  }

  labels               = var.user_labels
  redis_configs        = var.redis_configs
  replica_count        = var.replica_count
  read_replicas_mode   = var.read_replicas_mode
  customer_managed_key = var.customer_managed_key

  # Configure data persistence for durability
  # RDB snapshots ensure data recovery capability
  persistence_config {
    persistence_mode        = var.persistence_config.persistence_mode
    rdb_snapshot_period     = var.persistence_config.rdb_snapshot_period
    rdb_snapshot_start_time = var.persistence_config.rdb_snapshot_start_time != null ? var.persistence_config.rdb_snapshot_start_time : null
  }

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
} 