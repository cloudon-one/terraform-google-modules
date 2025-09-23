variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "instance_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
}

variable "database_version" {
  description = "The database version to use"
  type        = string
  default     = "POSTGRES_16"
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "machine_type" {
  description = "The machine type to use"
  type        = string
  default     = "db-n1-standard-2"
}

variable "disk_type" {
  description = "The disk type to use"
  type        = string
  default     = "PD_SSD"
}

variable "disk_size" {
  description = "The disk size in GB"
  type        = number
  default     = 100
}

variable "disk_autoresize" {
  description = "Whether to enable disk autoresize"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "The maximum disk size in GB for autoresize"
  type        = number
  default     = 0
}

variable "availability_type" {
  description = "The availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Availability type must be either ZONAL or REGIONAL."
  }
}

variable "primary_zone" {
  description = "The primary zone for the instance"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = true
}

variable "backup_configuration" {
  description = "Backup configuration"
  type = object({
    enabled                        = bool
    start_time                     = string
    point_in_time_recovery_enabled = bool
    transaction_log_retention_days = number
    retained_backups               = number
    location                       = optional(string)
  })
  default = {
    enabled                        = true
    start_time                     = "02:00"
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 7
    location                       = null
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day          = number
    hour         = number
    update_track = string
  })
  default = {
    day          = 7 # Sunday
    hour         = 2 # 2 AM
    update_track = "stable"
  }
}

variable "ip_configuration" {
  description = "IP configuration"
  type = object({
    ipv4_enabled                                  = bool
    private_network                               = string
    require_ssl                                   = bool
    allocated_ip_range                            = optional(string)
    enable_private_path_for_google_cloud_services = optional(bool)
    authorized_networks = list(object({
      name  = string
      value = string
    }))
  })
  default = {
    ipv4_enabled                                  = false
    private_network                               = null
    require_ssl                                   = true
    allocated_ip_range                            = null
    enable_private_path_for_google_cloud_services = false
    authorized_networks                           = []
  }
}

variable "database_flags" {
  description = "Database flags to set"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "insights_config" {
  description = "Query insights configuration"
  type = object({
    query_insights_enabled  = bool
    query_string_length     = number
    record_application_tags = bool
    record_client_address   = bool
  })
  default = {
    query_insights_enabled  = true
    query_string_length     = 1024
    record_application_tags = true
    record_client_address   = false
  }
}

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    name      = string
    charset   = optional(string)
    collation = optional(string)
  }))
  default = {}
}

variable "users" {
  description = "Map of users to create"
  type = map(object({
    name     = string
    host     = optional(string)
    password = optional(string)
  }))
  default = {}
}

variable "create_ssl_cert" {
  description = "Whether to create an SSL certificate"
  type        = bool
  default     = false
}

variable "ssl_cert_common_name" {
  description = "Common name for the SSL certificate"
  type        = string
  default     = "client-cert"
}

variable "read_replicas" {
  description = "Map of read replicas to create"
  type = map(object({
    region                = string
    zone                  = string
    machine_type          = string
    disk_type             = string
    disk_size             = number
    disk_autoresize       = bool
    disk_autoresize_limit = number
    deletion_protection   = bool
    ip_configuration = object({
      ipv4_enabled                                  = bool
      private_network                               = string
      require_ssl                                   = bool
      enable_private_path_for_google_cloud_services = optional(bool)
      authorized_networks = list(object({
        name  = string
        value = string
      }))
    })
  }))
  default = {}
}

variable "user_labels" {
  description = "User labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Timeouts for operations"
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

variable "edition" {
  description = "The edition of the instance (ENTERPRISE, ENTERPRISE_PLUS)"
  type        = string
  default     = "ENTERPRISE"
}

variable "data_cache_enabled" {
  description = "Whether to enable the data cache"
  type        = bool
  default     = false
}

variable "enable_google_ml_integration" {
  description = "Whether to enable Google ML integration"
  type        = bool
  default     = false
}

variable "retain_backups_on_delete" {
  description = "Whether to retain backups when instance is deleted"
  type        = bool
  default     = false
} 