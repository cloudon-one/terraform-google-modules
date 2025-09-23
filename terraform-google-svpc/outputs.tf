output "vpc_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_self_link" {
  description = "The self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet details"
  value = merge(
    {
      for name, subnet in google_compute_subnetwork.subnets : name => {
        id              = subnet.id
        self_link       = subnet.self_link
        ip_cidr_range   = subnet.ip_cidr_range
        region          = subnet.region
        gateway_address = subnet.gateway_address
      }
    },
    {
      for name, subnet in google_compute_subnetwork.proxy_subnets : name => {
        id              = subnet.id
        self_link       = subnet.self_link
        ip_cidr_range   = subnet.ip_cidr_range
        region          = subnet.region
        gateway_address = subnet.gateway_address
      }
    }
  )
}

output "cloud_nat" {
  description = "Cloud NAT details"
  value = {
    nat_id   = google_compute_router_nat.nat["nat"].id
    nat_name = google_compute_router_nat.nat["nat"].name
  }
}

output "firewall_rules" {
  description = "Map of firewall rule details"
  value = {
    for name, rule in google_compute_firewall.rules : name => {
      id        = rule.id
      self_link = rule.self_link
    }
  }
}

output "vpc_peering" {
  description = "Map of VPC peering details"
  value = {
    for name, peering in google_compute_network_peering.peering : name => {
      id           = peering.id
      name         = peering.name
      network      = peering.network
      peer_network = peering.peer_network
    }
  }
}

output "shared_vpc" {
  description = "Shared VPC details"
  value = var.enable_shared_vpc ? {
    host_project_id = google_compute_shared_vpc_host_project.shared_vpc_host[0].project
    service_projects = {
      for name, service in google_compute_shared_vpc_service_project.shared_vpc_service : name => service.service_project
    }
  } : null
}

output "dns_zones" {
  description = "Map of DNS zone details"
  value = {
    for name, zone in google_dns_managed_zone.private_zone : name => {
      id           = zone.id
      name_servers = zone.name_servers
    }
  }
}

output "dns_records" {
  description = "Map of DNS record details"
  value = {
    for name, record in google_dns_record_set.records : name => {
      id = record.id
    }
  }
}

output "dns_zone_names" {
  description = "Names of the private DNS zones"
  value       = { for k, zone in google_dns_managed_zone.private_zone : k => zone.name }
}

output "dns_zone_dns_names" {
  description = "DNS names of the private zones"
  value       = { for k, zone in google_dns_managed_zone.private_zone : k => zone.dns_name }
}

output "dns_zone_ids" {
  description = "IDs of the private DNS zones"
  value       = { for k, zone in google_dns_managed_zone.private_zone : k => zone.id }
} 