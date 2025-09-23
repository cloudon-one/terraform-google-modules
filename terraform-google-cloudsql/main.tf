# Create Cloud SQL instance with enterprise features
# Configured for high availability, security, and performance
resource "google_sql_database_instance" "instance" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier                        = var.machine_type
    disk_type                   = var.disk_type
    disk_size                   = var.disk_size
    disk_autoresize             = var.disk_autoresize
    disk_autoresize_limit       = var.disk_autoresize_limit
    availability_type           = var.availability_type
    deletion_protection_enabled = var.deletion_protection
    edition                     = var.edition
    # Configure automated backups and point-in-time recovery
    # Ensures data durability and disaster recovery capability
    backup_configuration {
      enabled                        = var.backup_configuration.enabled
      start_time                     = var.backup_configuration.start_time
      point_in_time_recovery_enabled = var.backup_configuration.point_in_time_recovery_enabled
      transaction_log_retention_days = var.backup_configuration.transaction_log_retention_days
      location                       = var.backup_configuration.location
      backup_retention_settings {
        retained_backups = var.backup_configuration.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # Schedule maintenance during specified window
    # Minimizes impact on production workloads
    maintenance_window {
      day          = var.maintenance_window.day
      hour         = var.maintenance_window.hour
      update_track = var.maintenance_window.update_track
    }
    # Configure network connectivity and security
    # Private IP only with SSL enforcement
    ip_configuration {
      ipv4_enabled                                  = var.ip_configuration.ipv4_enabled
      private_network                               = var.ip_configuration.private_network
      ssl_mode                                      = var.ip_configuration.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      allocated_ip_range                            = var.ip_configuration.allocated_ip_range
      enable_private_path_for_google_cloud_services = var.ip_configuration.enable_private_path_for_google_cloud_services

      dynamic "authorized_networks" {
        for_each = var.ip_configuration.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Enable Query Insights for performance monitoring
    # Tracks slow queries and application patterns
    insights_config {
      query_insights_enabled  = var.insights_config.query_insights_enabled
      query_string_length     = var.insights_config.query_string_length
      record_application_tags = var.insights_config.record_application_tags
      record_client_address   = var.insights_config.record_client_address
    }

    dynamic "location_preference" {
      for_each = var.availability_type == "REGIONAL" ? [1] : []
      content {
        zone = var.primary_zone
      }
    }

    user_labels = var.user_labels

    data_cache_config {
      data_cache_enabled = var.data_cache_enabled
    }

    enable_google_ml_integration = var.enable_google_ml_integration
    retain_backups_on_delete     = var.retain_backups_on_delete
  }

  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [
      settings[0].user_labels,
      deletion_protection
    ]
  }
}

# Create databases within the SQL instance
# Each database can have specific charset and collation
resource "google_sql_database" "databases" {
  for_each = var.databases

  name     = each.value.name
  instance = google_sql_database_instance.instance.name
  project  = var.project_id

  charset   = lookup(each.value, "charset", null)
  collation = lookup(each.value, "collation", null)
}

resource "google_sql_user" "users" {
  for_each = var.users

  name     = each.value.name
  instance = google_sql_database_instance.instance.name
  project  = var.project_id
  host     = contains(["MYSQL_5_6", "MYSQL_5_7", "MYSQL_8_0"], var.database_version) ? lookup(each.value, "host", "%") : null
  password = lookup(each.value, "password", null)
}

resource "google_sql_ssl_cert" "client_cert" {
  count = var.create_ssl_cert ? 1 : 0

  common_name = var.ssl_cert_common_name
  instance    = google_sql_database_instance.instance.name
  project     = var.project_id
}
resource "google_sql_database_instance" "read_replicas" {
  for_each = var.read_replicas

  name                 = each.key == "replica" ? "${var.instance_name}-replica" : "${var.instance_name}-replica-${each.key}"
  database_version     = var.database_version
  region               = each.value.region
  project              = var.project_id
  master_instance_name = google_sql_database_instance.instance.name

  settings {
    tier                        = each.value.machine_type
    disk_type                   = each.value.disk_type
    disk_size                   = each.value.disk_size
    disk_autoresize             = each.value.disk_autoresize
    disk_autoresize_limit       = each.value.disk_autoresize_limit
    deletion_protection_enabled = each.value.deletion_protection

    ip_configuration {
      ipv4_enabled                                  = each.value.ip_configuration.ipv4_enabled
      private_network                               = each.value.ip_configuration.private_network != null ? each.value.ip_configuration.private_network : var.ip_configuration.private_network
      ssl_mode                                      = each.value.ip_configuration.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      allocated_ip_range                            = lookup(each.value.ip_configuration, "allocated_ip_range", null)
      enable_private_path_for_google_cloud_services = lookup(each.value.ip_configuration, "enable_private_path_for_google_cloud_services", false)

      dynamic "authorized_networks" {
        for_each = each.value.ip_configuration.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    location_preference {
      zone = each.value.zone
    }
    user_labels = merge(var.user_labels, {
      replica_of = var.instance_name
      replica_id = each.key
    })
  }

  deletion_protection = each.value.deletion_protection

  lifecycle {
    ignore_changes = [
      settings[0].database_flags,
      settings[0].enable_google_ml_integration,
      settings[0].active_directory_config,
      settings[0].sql_server_audit_config,
      settings[0].ip_configuration[0].psc_config,
      settings[0].ip_configuration[0].enable_private_path_for_google_cloud_services,
      settings[0].user_labels,
      deletion_protection
    ]
  }
} 