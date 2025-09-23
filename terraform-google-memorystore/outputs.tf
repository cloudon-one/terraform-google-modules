output "instance_name" {
  description = "The name of the Memorystore Redis instance"
  value       = google_redis_instance.cache.name
}

output "instance_id" {
  description = "The ID of the Memorystore Redis instance"
  value       = google_redis_instance.cache.id
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed"
  value       = google_redis_instance.cache.current_location_id
}

output "host" {
  description = "The IP address of the instance"
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "The port number of the instance"
  value       = google_redis_instance.cache.port
}

output "redis_configs" {
  description = "The Redis configuration parameters"
  value       = google_redis_instance.cache.redis_configs
}

output "auth_string" {
  description = "The AUTH string for the Redis instance"
  value       = google_redis_instance.cache.auth_string
  sensitive   = true
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = google_redis_instance.cache.server_ca_certs
}

output "persistence_iam_identity" {
  description = "The Cloud IAM identity associated with this instance"
  value       = google_redis_instance.cache.persistence_iam_identity
}

output "tier" {
  description = "The service tier of the instance"
  value       = google_redis_instance.cache.tier
}

output "memory_size_gb" {
  description = "Redis memory size in GB"
  value       = google_redis_instance.cache.memory_size_gb
}

output "redis_version" {
  description = "The version of Redis software"
  value       = google_redis_instance.cache.redis_version
}

output "connect_mode" {
  description = "The connection mode of the Redis instance"
  value       = google_redis_instance.cache.connect_mode
}

output "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance"
  value       = google_redis_instance.cache.auth_enabled
}

output "transit_encryption_mode" {
  description = "The TLS encryption mode for the Redis instance"
  value       = google_redis_instance.cache.transit_encryption_mode
}

output "replica_count" {
  description = "The number of replica nodes"
  value       = google_redis_instance.cache.replica_count
}

output "read_replicas_mode" {
  description = "Read replicas mode"
  value       = google_redis_instance.cache.read_replicas_mode
}

output "maintenance_policy" {
  description = "Maintenance policy information"
  value = {
    day    = google_redis_instance.cache.maintenance_policy[0].weekly_maintenance_window[0].day
    hour   = google_redis_instance.cache.maintenance_policy[0].weekly_maintenance_window[0].start_time[0].hours
    minute = google_redis_instance.cache.maintenance_policy[0].weekly_maintenance_window[0].start_time[0].minutes
  }
}

output "persistence_config" {
  description = "Persistence configuration information"
  value = {
    persistence_mode    = google_redis_instance.cache.persistence_config[0].persistence_mode
    rdb_snapshot_period = google_redis_instance.cache.persistence_config[0].rdb_snapshot_period
  }
}

output "labels" {
  description = "Resource labels"
  value       = google_redis_instance.cache.labels
}

output "connection_string" {
  description = "Redis connection string (host:port)"
  value       = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
} 