output "access_policy_name" {
  description = "The name of the created access policy"
  value       = google_access_context_manager_access_policy.policy.name
}

output "access_policy_id" {
  description = "The ID of the created access policy"
  value       = google_access_context_manager_access_policy.policy.id
}

output "main_perimeter_name" {
  description = "The name of the main service perimeter"
  value       = google_access_context_manager_service_perimeter.main_perimeter.name
}

output "bridge_perimeter_name" {
  description = "The name of the bridge service perimeter"
  value       = google_access_context_manager_service_perimeter.bridge_perimeter.name
}

output "vpc_sc_perimeter_name" {
  description = "The name of the VPC SC service perimeter"
  value       = google_access_context_manager_service_perimeter.vpc_sc_perimeter.name
}

output "access_levels" {
  description = "Map of created access levels"
  value = {
    for level in google_access_context_manager_access_levels.access_levels.access_levels :
    level.title => level.name
  }
}

output "protected_projects" {
  description = "List of projects protected by the service perimeters"
  value = [
    var.host_project_id,
    var.gke_project_id,
    var.data_project_id
  ]
}

output "restricted_services" {
  description = "List of services restricted by the main perimeter"
  value       = var.restricted_services
}

output "bridge_services" {
  description = "List of services in the bridge perimeter"
  value       = var.bridge_services
}

output "vpc_restricted_services" {
  description = "List of VPC-specific restricted services"
  value       = var.vpc_restricted_services
} 