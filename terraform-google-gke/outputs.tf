output "cluster_name" {
  description = "The name of the cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "The ID of the cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "The IP address of the cluster endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  value       = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "service_account_email" {
  description = "The email of the service account created for the cluster"
  value       = var.create_service_account ? google_service_account.gke_service_account[0].email : null
}

output "node_pools" {
  description = "List of node pools"
  value = {
    for name, pool in google_container_node_pool.node_pools : name => {
      name       = pool.name
      node_count = pool.node_count
      locations  = pool.location
    }
  }
}

output "instance_group_urls" {
  description = "Map of node pool names to their instance group URLs"
  value = {
    for name, pool in google_container_node_pool.node_pools : name => pool.instance_group_urls
  }
}

output "cluster_self_link" {
  description = "The self link of the cluster"
  value       = google_container_cluster.primary.self_link
}

output "cluster_location" {
  description = "The location (zone/region) of the cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_zone" {
  description = "The zone of the cluster if regional=false"
  value       = google_container_cluster.primary.location
}

output "master_version" {
  description = "The current master version"
  value       = google_container_cluster.primary.master_version
}

output "services_ipv4_cidr" {
  description = "The IP range of the Kubernetes services"
  value       = google_container_cluster.primary.services_ipv4_cidr
}

output "cluster_ipv4_cidr" {
  description = "The IP range of the Kubernetes pods"
  value       = google_container_cluster.primary.cluster_ipv4_cidr
}

output "network_self_link" {
  description = "The VPC network self link"
  value       = google_container_cluster.primary.network
}

output "subnetwork_self_link" {
  description = "The subnetwork self link"
  value       = google_container_cluster.primary.subnetwork
}

output "workload_identity_pool" {
  description = "The Workload Identity pool ID"
  value       = "${var.project_id}.svc.id.goog"
}

output "cluster_security_posture" {
  description = "Security posture configuration details"
  value = {
    mode               = google_container_cluster.primary.security_posture_config[0].mode
    vulnerability_mode = google_container_cluster.primary.security_posture_config[0].vulnerability_mode
  }
}

output "database_encryption" {
  description = "Database encryption configuration"
  value = {
    state    = google_container_cluster.primary.database_encryption[0].state
    key_name = google_container_cluster.primary.database_encryption[0].key_name
  }
  sensitive = true
} 