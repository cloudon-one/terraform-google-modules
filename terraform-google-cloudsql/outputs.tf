output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.name
}

output "instance_id" {
  description = "The ID of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.id
}

output "connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.connection_name
}

output "first_ip_address" {
  description = "The first IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.first_ip_address
}

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.public_ip_address
}

output "self_link" {
  description = "The URI of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.self_link
}

output "service_account_email_address" {
  description = "The service account email address of the Cloud SQL instance"
  value       = google_sql_database_instance.instance.service_account_email_address
}

output "databases" {
  description = "Map of created databases"
  value = {
    for name, db in google_sql_database.databases : name => {
      name      = db.name
      charset   = db.charset
      collation = db.collation
    }
  }
}

output "users" {
  description = "Map of created users"
  value = {
    for name, user in google_sql_user.users : name => {
      name = user.name
      host = user.host
    }
  }
}

output "ssl_cert" {
  description = "SSL certificate information"
  value = var.create_ssl_cert ? {
    cert_serial_number = google_sql_ssl_cert.client_cert[0].cert_serial_number
    common_name        = google_sql_ssl_cert.client_cert[0].common_name
    create_time        = google_sql_ssl_cert.client_cert[0].create_time
    expiration_time    = google_sql_ssl_cert.client_cert[0].expiration_time
    sha1_fingerprint   = google_sql_ssl_cert.client_cert[0].sha1_fingerprint
  } : null
}

output "read_replicas" {
  description = "Map of read replicas"
  value = {
    for name, replica in google_sql_database_instance.read_replicas : name => {
      name               = replica.name
      id                 = replica.id
      connection_name    = replica.connection_name
      first_ip_address   = replica.first_ip_address
      private_ip_address = replica.private_ip_address
      public_ip_address  = replica.public_ip_address
      self_link          = replica.self_link
    }
  }
}

output "instance_settings" {
  description = "Instance settings information"
  value = {
    tier                     = google_sql_database_instance.instance.settings[0].tier
    disk_type                = google_sql_database_instance.instance.settings[0].disk_type
    disk_size                = google_sql_database_instance.instance.settings[0].disk_size
    availability_type        = google_sql_database_instance.instance.settings[0].availability_type
    backup_enabled           = google_sql_database_instance.instance.settings[0].backup_configuration[0].enabled
    backup_start_time        = google_sql_database_instance.instance.settings[0].backup_configuration[0].start_time
    point_in_time_recovery   = google_sql_database_instance.instance.settings[0].backup_configuration[0].point_in_time_recovery_enabled
    maintenance_window_day   = google_sql_database_instance.instance.settings[0].maintenance_window[0].day
    maintenance_window_hour  = google_sql_database_instance.instance.settings[0].maintenance_window[0].hour
    maintenance_window_track = google_sql_database_instance.instance.settings[0].maintenance_window[0].update_track
    ipv4_enabled             = google_sql_database_instance.instance.settings[0].ip_configuration[0].ipv4_enabled
    ssl_mode                 = google_sql_database_instance.instance.settings[0].ip_configuration[0].ssl_mode
    insights_enabled         = google_sql_database_instance.instance.settings[0].insights_config[0].query_insights_enabled
  }
} 