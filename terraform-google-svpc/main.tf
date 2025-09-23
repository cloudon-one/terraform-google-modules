# Create VPC network with custom subnets
# Foundation for Shared VPC architecture
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = var.auto_create_subnetworks
  project                 = var.project_id
  routing_mode            = var.routing_mode
  mtu                     = var.mtu

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
# Create standard subnets for workloads
# Excludes proxy subnets which are handled separately
resource "google_compute_subnetwork" "subnets" {
  for_each                 = { for k, v in var.subnets : k => v if try(v.purpose, null) != "REGIONAL_MANAGED_PROXY" }
  name                     = each.value.name
  ip_cidr_range            = each.value.ip_cidr_range
  region                   = each.value.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}

# Create regional managed proxy subnets
# Required for internal HTTP(S) load balancers
resource "google_compute_subnetwork" "proxy_subnets" {
  provider      = google-beta
  for_each      = { for k, v in var.subnets : k => v if try(v.purpose, null) == "REGIONAL_MANAGED_PROXY" }
  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  project       = var.project_id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      aggregation_interval = log_config.value.aggregation_interval
      flow_sampling        = log_config.value.flow_sampling
      metadata             = log_config.value.metadata
    }
  }
}

# Create Cloud Router for NAT gateway
# Enables outbound internet connectivity for private instances
resource "google_compute_router" "router" {
  for_each = var.cloud_nat_config != null ? { "nat" = var.cloud_nat_config } : {}

  name    = each.value.router_name
  region  = each.value.router_region
  network = google_compute_network.vpc.id
  project = var.project_id

  bgp {
    asn = each.value.router_asn
  }
}

# Configure Cloud NAT for secure outbound connectivity
# Allows private instances to reach internet without public IPs
resource "google_compute_router_nat" "nat" {
  for_each                           = var.cloud_nat_config != null ? { "nat" = var.cloud_nat_config } : {}
  name                               = each.value.nat_name
  router                             = google_compute_router.router["nat"].name
  region                             = each.value.router_region
  project                            = var.project_id
  nat_ip_allocate_option             = each.value.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat

  dynamic "subnetwork" {
    for_each = each.value.subnetworks
    content {
      name                    = subnetwork.value.name
      source_ip_ranges_to_nat = subnetwork.value.source_ip_ranges_to_nat
    }
  }

  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    content {
      enable = log_config.value.enable
      filter = log_config.value.filter
    }
  }

  lifecycle {
    ignore_changes = [
      min_ports_per_vm,
      max_ports_per_vm,
      enable_endpoint_independent_mapping,
      tcp_established_idle_timeout_sec,
      tcp_transitory_idle_timeout_sec,
      udp_idle_timeout_sec,
      icmp_idle_timeout_sec
    ]
  }
}

# Create firewall rules for network security
# Controls traffic flow between resources
resource "google_compute_firewall" "rules" {
  for_each    = var.firewall_rules
  name        = each.value.name
  network     = google_compute_network.vpc.id
  description = each.value.description
  direction   = each.value.direction
  disabled    = each.value.disabled

  dynamic "log_config" {
    for_each = each.value.enable_logging == true ? [1] : []
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }

  priority                = each.value.priority
  source_ranges           = each.value.direction == "INGRESS" ? each.value.source_ranges : null
  destination_ranges      = each.value.direction == "EGRESS" ? each.value.destination_ranges : null
  source_tags             = each.value.source_tags
  source_service_accounts = each.value.source_service_accounts
  target_tags             = each.value.target_tags
  target_service_accounts = each.value.target_service_accounts


  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.deny
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }
}

resource "google_compute_network_peering" "peering" {
  for_each             = var.vpc_peering_config
  name                 = each.value.name
  network              = google_compute_network.vpc.id
  peer_network         = each.value.peer_network
  export_custom_routes = each.value.export_custom_routes
  import_custom_routes = each.value.import_custom_routes
}

resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {
  count   = var.enable_shared_vpc ? 1 : 0
  project = var.project_id
}

resource "google_compute_shared_vpc_service_project" "shared_vpc_service" {
  for_each = var.enable_shared_vpc ? var.service_projects : {}

  host_project    = var.project_id
  service_project = each.value
}

resource "google_compute_subnetwork_iam_binding" "subnet_users" {
  for_each   = var.enable_shared_vpc ? var.subnet_iam_bindings : {}
  project    = var.project_id
  region     = each.value.region
  subnetwork = each.value.subnetwork
  role       = "roles/compute.networkUser"
  members    = each.value.members
}

resource "google_dns_managed_zone" "private_zone" {
  for_each    = var.dns_config
  name        = each.value.name
  dns_name    = each.value.dns_name
  project     = var.project_id
  description = each.value.description
  visibility  = "private"

  private_visibility_config {
    dynamic "networks" {
      for_each = each.value.networks
      content {
        network_url = networks.value
      }
    }
  }

  labels = merge(var.labels, each.value.labels)
}

resource "google_dns_record_set" "records" {
  for_each     = var.dns_records
  name         = each.value.name
  managed_zone = google_dns_managed_zone.private_zone[each.value.zone_key].name
  type         = each.value.type
  ttl          = each.value.ttl
  project      = var.project_id
  rrdatas      = each.value.rrdatas
}

resource "google_compute_global_address" "private_service_access" {
  for_each      = var.private_service_access_ranges
  name          = each.value.name
  purpose       = each.value.purpose
  address_type  = each.value.address_type
  ip_version    = "IPV4"
  prefix_length = split("/", each.value.ip_cidr_range)[1]
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_service_access" {
  count                   = length(var.private_service_access_ranges) > 0 ? 1 : 0
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [for range in google_compute_global_address.private_service_access : range.name]
} 