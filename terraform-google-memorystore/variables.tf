variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "instance_name" {
  description = "The name of the Memorystore Redis instance"
  type        = string
}

variable "tier" {
  description = "The service tier of the instance"
  type        = string
  default     = "STANDARD_HA"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Tier must be either BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 300
    error_message = "Memory size must be between 1 and 300 GB."
  }
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "redis_version" {
  description = "The version of Redis software"
  type        = string
  default     = "REDIS_7_0"
  validation {
    condition     = contains(["REDIS_5_0", "REDIS_6_X", "REDIS_7_0"], var.redis_version)
    error_message = "Redis version must be REDIS_5_0, REDIS_6_X, or REDIS_7_0."
  }
}

variable "authorized_network" {
  description = "The full name of the network that should be peered with Google Cloud"
  type        = string
  default     = null
}

variable "connect_mode" {
  description = "The connection mode of the Redis instance"
  type        = string
  default     = "PRIVATE_SERVICE_ACCESS"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "Connect mode must be either DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  }
}

variable "auth_enabled" {
  description = "Indicates whether OSS Redis AUTH is enabled for the instance"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "The TLS encryption mode for the Redis instance"
  type        = string
  default     = "SERVER_AUTHENTICATION"
  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "Transit encryption mode must be either DISABLED or SERVER_AUTHENTICATION."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day    = string
    hour   = number
    minute = number
  })
  default = {
    day    = "SUNDAY"
    hour   = 2 # 2 AM
    minute = 0
  }
  validation {
    condition = contains([
      "DAY_OF_WEEK_UNSPECIFIED",
      "MONDAY",
      "TUESDAY",
      "WEDNESDAY",
      "THURSDAY",
      "FRIDAY",
      "SATURDAY",
      "SUNDAY"
    ], var.maintenance_window.day)
    error_message = "Day must be one of: DAY_OF_WEEK_UNSPECIFIED, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY."
  }
}

variable "user_labels" {
  description = "User labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "redis_configs" {
  description = "Redis configuration parameters"
  type        = map(string)
  default     = {}
}

variable "replica_count" {
  description = "The number of replica nodes"
  type        = number
  default     = 1
  validation {
    condition     = var.replica_count >= 0 && var.replica_count <= 5
    error_message = "Replica count must be between 0 and 5."
  }
}

variable "read_replicas_mode" {
  description = "Read replicas mode"
  type        = string
  default     = "READ_REPLICAS_ENABLED"
  validation {
    condition     = contains(["READ_REPLICAS_ENABLED", "READ_REPLICAS_DISABLED"], var.read_replicas_mode)
    error_message = "Read replicas mode must be either READ_REPLICAS_ENABLED or READ_REPLICAS_DISABLED."
  }
}

variable "customer_managed_key" {
  description = "The KMS key reference that you provisioned for this instance"
  type        = string
  default     = null
}

variable "persistence_config" {
  description = "Persistence configuration"
  type = object({
    persistence_mode        = string
    rdb_snapshot_period     = string
    rdb_snapshot_start_time = optional(string)
  })
  default = {
    persistence_mode        = "RDB"
    rdb_snapshot_period     = "TWENTY_FOUR_HOURS"
    rdb_snapshot_start_time = null
  }
  validation {
    condition     = contains(["DISABLED", "RDB"], var.persistence_config.persistence_mode)
    error_message = "Persistence mode must be either DISABLED or RDB."
  }
}

variable "reserved_ip_range" {
  description = "The IP address range of the instance"
  type        = string
  default     = null
} 