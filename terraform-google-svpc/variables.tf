variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "When set to true, the network is created in auto subnet mode"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "The network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "GLOBAL"
}

variable "mtu" {
  description = "The network MTU"
  type        = number
  default     = 1460
}

variable "timeouts" {
  description = "Custom timeout options for the VPC network"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "subnets" {
  description = "The list of subnets to create"
  type = map(object({
    name                     = string
    ip_cidr_range            = string
    region                   = string
    private_ip_google_access = optional(bool, true)
    purpose                  = optional(string)
    role                     = optional(string)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
    log_config = optional(object({
      aggregation_interval = string
      flow_sampling        = number
      metadata             = string
    }))
    labels = optional(map(string), {})
  }))
  default = {}
}

variable "cloud_nat_config" {
  description = "Configuration for Cloud NAT"
  type = object({
    router_name                         = string
    router_region                       = string
    router_asn                          = number
    nat_name                            = string
    nat_ip_allocate_option              = string
    source_subnetwork_ip_ranges_to_nat  = string
    min_ports_per_vm                    = optional(number)
    max_ports_per_vm                    = optional(number)
    enable_endpoint_independent_mapping = optional(bool)
    tcp_established_idle_timeout_sec    = optional(number)
    tcp_transitory_idle_timeout_sec     = optional(number)
    udp_idle_timeout_sec                = optional(number)
    icmp_idle_timeout_sec               = optional(number)
    subnetworks = optional(list(object({
      name                    = string
      source_ip_ranges_to_nat = string
    })), [])
    log_config = optional(object({
      enable = bool
      filter = string
    }))
    labels = optional(map(string), {})
  })
  default = null
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = map(object({
    name                    = string
    description             = optional(string)
    direction               = string
    disabled                = optional(bool, false)
    enable_logging          = optional(bool, true)
    priority                = optional(number, 1000)
    source_ranges           = optional(list(string))
    destination_ranges      = optional(list(string))
    source_tags             = optional(list(string))
    source_service_accounts = optional(list(string))
    target_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    labels = optional(map(string), {})
  }))
  default = {}
}

variable "vpc_peering_config" {
  description = "Configuration for VPC peering"
  type = map(object({
    name                 = string
    peer_network         = string
    auto_create_routes   = optional(bool, true)
    export_custom_routes = optional(bool, false)
    import_custom_routes = optional(bool, false)
  }))
  default = {}
}

variable "enable_shared_vpc" {
  description = "Whether to enable Shared VPC"
  type        = bool
  default     = false
}

variable "service_projects" {
  description = "List of service projects to attach to the Shared VPC"
  type        = map(string)
  default     = {}
}

variable "subnet_iam_bindings" {
  description = "IAM bindings for subnet-level access control"
  type = map(object({
    subnetwork = string
    region     = string
    members    = list(string)
  }))
  default = {}
}

variable "dns_config" {
  description = "Configuration for private DNS zones"
  type = map(object({
    name        = string
    dns_name    = string
    description = optional(string)
    networks    = list(string)
    labels      = optional(map(string), {})
  }))
  default = {}
}

variable "dns_records" {
  description = "List of DNS records to create"
  type = map(object({
    name     = string
    zone_key = string
    type     = string
    ttl      = number
    rrdatas  = list(string)
  }))
  default = {}
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "zone_name" {
  description = "Name of the DNS zone"
  type        = string
}

variable "dns_name" {
  description = "DNS name for the zone"
  type        = string
}

variable "gke_vpc_self_link" {
  description = "Self link of the GKE VPC network"
  type        = string
}

variable "data_vpc_self_link" {
  description = "Self link of the Data VPC network"
  type        = string
}

variable "gke_service_records" {
  description = "Map of GKE service DNS records"
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    rrdatas = list(string)
  }))
  default = {}
}

variable "data_service_records" {
  description = "Map of data service DNS records"
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    rrdatas = list(string)
  }))
  default = {}
}

variable "private_service_access_ranges" {
  description = "Map of private service access IP ranges"
  type = map(object({
    name          = string
    ip_cidr_range = string
    purpose       = optional(string, "VPC_PEERING")
    address_type  = optional(string, "INTERNAL")
  }))
  default = {}
} 