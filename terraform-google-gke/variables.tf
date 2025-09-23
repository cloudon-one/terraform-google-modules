variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "network" {
  description = "The VPC network to host the cluster in"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation to use for the hosted master network"
  type        = string
}

variable "private_endpoint_subnetwork" {
  description = "The subnetwork for the private endpoint"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for the cluster"
  type        = bool
  default     = true
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "ip_allocation_policy" {
  description = "IP allocation policy for the cluster"
  type = object({
    cluster_secondary_range_name  = string
    services_secondary_range_name = string
    cluster_ipv4_cidr_block       = optional(string)
    services_ipv4_cidr_block      = optional(string)
  })
}

variable "release_channel" {
  description = "The release channel of this cluster"
  type        = string
  default     = "STABLE"
}

variable "enable_network_policy" {
  description = "Whether to enable network policy enforcement"
  type        = bool
  default     = true
}

variable "enable_http_load_balancing" {
  description = "Whether to enable HTTP load balancing"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Whether to enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Whether to enable vertical pod autoscaling"
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    daily_window_start_time = optional(string)
    recurring_window = optional(object({
      start_time = string
      end_time   = string
      recurrence = string
    }))
  })
  default = {
    daily_window_start_time = "03:00"
    recurring_window        = null
  }
}

variable "security" {
  description = "Security configuration"
  type = object({
    mode = string
  })
  default = {
    mode = "BASIC"
  }
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    enable_components         = list(string)
    enable_managed_prometheus = bool
  })
  default = {
    enable_components         = ["SYSTEM_COMPONENTS", "WORKLOADS"]
    enable_managed_prometheus = true
  }
}

variable "logging" {
  description = "Logging configuration"
  type = object({
    enable_components = list(string)
  })
  default = {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection"
  type        = bool
  default     = true
}

variable "create_service_account" {
  description = "Whether to create a service account for the cluster"
  type        = bool
  default     = true
}

variable "resource_labels" {
  description = "Resource labels for the cluster"
  type        = map(string)
  default     = {}
}

variable "confidential_nodes" {
  description = "Confidential nodes configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "dns_config" {
  description = "DNS configuration"
  type = object({
    cluster_dns_domain = string
  })
  default = {
    cluster_dns_domain = "cluster.local"
  }
}

variable "gateway_api_config" {
  description = "Gateway API configuration"
  type = object({
    channel = string
  })
  default = {
    channel = "CHANNEL_STANDARD"
  }
}

variable "default_snat_status" {
  description = "Default SNAT status configuration"
  type = object({
    disabled = bool
  })
  default = {
    disabled = false
  }
}

variable "service_external_ips_config" {
  description = "Service external IPs configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "vertical_pod_autoscaling" {
  description = "Vertical pod autoscaling configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "cluster_autoscaling" {
  description = "Cluster autoscaling configuration"
  type = object({
    enabled                     = bool
    autoscaling_profile         = string
    auto_provisioning_locations = list(string)
    auto_provisioning_defaults = object({
      disk_size       = number
      disk_type       = string
      image_type      = string
      oauth_scopes    = list(string)
      service_account = string
      management = object({
        auto_repair  = bool
        auto_upgrade = bool
        upgrade_settings = object({
          max_surge       = number
          max_unavailable = number
          strategy        = string
        })
      })
      shielded_instance_config = object({
        enable_integrity_monitoring = bool
        enable_secure_boot          = bool
      })
    })
    resource_limits = list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    }))
  })
  default = {
    enabled                     = false
    autoscaling_profile         = "BALANCED"
    auto_provisioning_locations = []
    auto_provisioning_defaults = {
      disk_size       = 100
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform", "https://www.googleapis.com/auth/userinfo.email"]
      service_account = ""
      management = {
        auto_repair  = true
        auto_upgrade = true
        upgrade_settings = {
          max_surge       = 1
          max_unavailable = 0
          strategy        = "SURGE"
        }
      }
      shielded_instance_config = {
        enable_integrity_monitoring = true
        enable_secure_boot          = false
      }
    }
    resource_limits = []
  }
}

variable "addons_config" {
  description = "Addons configuration"
  type = object({
    dns_cache_config = object({
      enabled = bool
    })
    gce_persistent_disk_csi_driver_config = object({
      enabled = bool
    })
    gcp_filestore_csi_driver_config = object({
      enabled = bool
    })
    gcs_fuse_csi_driver_config = object({
      enabled = bool
    })
    gke_backup_agent_config = object({
      enabled = bool
    })
    network_policy_config = object({
      disabled = bool
    })
    ray_operator_config = object({
      enabled = bool
      ray_cluster_logging_config = object({
        enabled = bool
      })
      ray_cluster_monitoring_config = object({
        enabled = bool
      })
    })
    stateful_ha_config = object({
      enabled = bool
    })
  })
  default = {
    dns_cache_config = {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config = {
      enabled = true
    }
    gcp_filestore_csi_driver_config = {
      enabled = true
    }
    gcs_fuse_csi_driver_config = {
      enabled = true
    }
    gke_backup_agent_config = {
      enabled = true
    }
    network_policy_config = {
      disabled = true
    }
    ray_operator_config = {
      enabled = true
      ray_cluster_logging_config = {
        enabled = true
      }
      ray_cluster_monitoring_config = {
        enabled = true
      }
    }
    stateful_ha_config = {
      enabled = false
    }
  }
}

variable "security_posture_config" {
  description = "Security posture configuration"
  type = object({
    mode               = string
    vulnerability_mode = string
  })
  default = {
    mode               = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }
}

variable "cost_management_config" {
  description = "Cost management configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "notification_config" {
  description = "Notification configuration"
  type = object({
    pubsub = object({
      enabled = bool
      topic   = optional(string)
    })
  })
  default = {
    pubsub = {
      enabled = false
      topic   = null
    }
  }
}

variable "node_pool_auto_config" {
  description = "Node pool auto configuration"
  type = object({
    resource_manager_tags = map(string)
    network_tags = object({
      tags = list(string)
    })
    node_kubelet_config = object({
      insecure_kubelet_readonly_port_enabled = string
    })
  })
  default = {
    resource_manager_tags = {}
    network_tags = {
      tags = ["gke-node"]
    }
    node_kubelet_config = {
      insecure_kubelet_readonly_port_enabled = "FALSE"
    }
  }
}

variable "node_pool_defaults" {
  description = "Node pool defaults configuration"
  type = object({
    node_config_defaults = object({
      insecure_kubelet_readonly_port_enabled = string
      logging_variant                        = string
    })
  })
  default = {
    node_config_defaults = {
      insecure_kubelet_readonly_port_enabled = "FALSE"
      logging_variant                        = "DEFAULT"
    }
  }
}

variable "master_auth" {
  description = "Master auth configuration"
  type = object({
    client_certificate_config = object({
      issue_client_certificate = bool
    })
  })
  default = {
    client_certificate_config = {
      issue_client_certificate = false
    }
  }
}

variable "authenticator_groups_config" {
  description = "Authenticator groups configuration"
  type = object({
    security_group = string
  })
  default = {
    security_group = ""
  }
}

variable "mesh_certificates" {
  description = "Mesh certificates configuration"
  type = object({
    enable_certificates = bool
  })
  default = {
    enable_certificates = false
  }
}

variable "identity_service_config" {
  description = "Identity service configuration"
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "node_pools" {
  description = "List of node pools to create"
  type = map(object({
    name              = string
    node_count        = number
    machine_type      = string
    disk_size_gb      = number
    disk_type         = string
    version           = optional(string)
    node_locations    = optional(list(string))
    max_pods_per_node = optional(number)
    service_account   = optional(string)
    oauth_scopes      = optional(list(string))
    labels            = map(string)
    tags              = optional(list(string))
    metadata          = optional(map(string))
    resource_labels   = optional(map(string))
    boot_disk_kms_key = optional(string)
    confidential_nodes = optional(object({
      enabled = bool
    }))
    shielded_instance_config = optional(object({
      enable_integrity_monitoring = bool
      enable_secure_boot          = bool
    }))
    advanced_machine_features = optional(object({
      enable_nested_virtualization = bool
      threads_per_core             = number
    }))
    kubelet_config = optional(object({
      cpu_cfs_quota                          = bool
      insecure_kubelet_readonly_port_enabled = string
      pod_pids_limit                         = number
      cpu_manager_policy                     = string
    }))
    enable_confidential_storage = optional(bool)
    logging_variant             = optional(string)
    local_ssd_count             = optional(number)
    guest_accelerator = optional(list(object({
      count = number
      type  = string
    })))
    image_type            = optional(string)
    preemptible           = optional(bool)
    spot                  = optional(bool)
    resource_manager_tags = optional(map(string))
    effective_taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
    gcfs_config = optional(object({
      enabled = bool
    }))
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    autoscaling = object({
      min_node_count       = number
      max_node_count       = number
      location_policy      = string
      total_min_node_count = optional(number)
      total_max_node_count = optional(number)
    })
    management = object({
      auto_repair  = bool
      auto_upgrade = bool
    })
    upgrade_settings = optional(object({
      max_surge       = number
      max_unavailable = number
      strategy        = string
    }))
    network_config = optional(object({
      create_pod_range     = bool
      enable_private_nodes = bool
      pod_ipv4_cidr_block  = string
      pod_range            = string
    }))
    queued_provisioning = optional(object({
      enabled = bool
    }))
  }))
}

variable "timeouts" {
  description = "Timeout configuration"
  type = object({
    create = string
    update = string
    delete = string
  })
  default = {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "database_encryption" {
  description = "Application-layer secrets encryption configuration"
  type = object({
    state    = string
    key_name = string
  })
  default = {
    state    = "DECRYPTED"
    key_name = null
  }
}

variable "datapath_provider" {
  description = "The desired datapath provider for this cluster"
  type        = string
  default     = "ADVANCED_DATAPATH"
}

variable "enable_intranode_visibility" {
  description = "Whether to enable intra-node visibility"
  type        = bool
  default     = false
}

variable "enable_fqdn_network_policy" {
  description = "Whether to enable FQDN network policy"
  type        = bool
  default     = false
}

variable "enable_secret_manager" {
  description = "Whether to enable Secret Manager integration"
  type        = bool
  default     = false
}

variable "enable_application_monitoring" {
  description = "Whether to enable application monitoring"
  type        = bool
  default     = false
}

variable "pod_security_standards" {
  description = "Pod Security Standards configuration"
  type = object({
    mode    = string
    version = string
  })
  default = {
    mode    = "BASELINE"
    version = "v1.32"
  }

  validation {
    condition     = contains(["DISABLED", "BASELINE", "RESTRICTED", "ENFORCED"], var.pod_security_standards.mode)
    error_message = "Pod Security Standards mode must be one of: DISABLED, BASELINE, RESTRICTED, ENFORCED."
  }

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+$", var.pod_security_standards.version))
    error_message = "Pod Security Standards version must be in format vX.Y (e.g., v1.32)."
  }
}

variable "binary_authorization" {
  description = "Binary authorization configuration"
  type = object({
    evaluation_mode = string
  })
  default = {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  validation {
    condition     = contains(["DISABLED", "PROJECT_SINGLETON_POLICY_ENFORCE"], var.binary_authorization.evaluation_mode)
    error_message = "Binary authorization evaluation mode must be one of: DISABLED, PROJECT_SINGLETON_POLICY_ENFORCE."
  }
}

variable "enable_master_global_access" {
  description = "Whether to enable global access to the master endpoint"
  type        = bool
  default     = false
}

variable "enable_gcp_public_cidrs_access" {
  description = "Whether to enable access from GCP public IP addresses"
  type        = bool
  default     = false
} 