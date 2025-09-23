output "host_project" {
  description = "Host project details"
  value = {
    project_id = google_project.host_project.project_id
    name       = google_project.host_project.name
    number     = google_project.host_project.number
  }
}

output "host_project_id" {
  description = "The ID of the host project"
  value       = google_project.host_project.project_id
}

output "host_project_number" {
  description = "The project number of the host project"
  value       = google_project.host_project.number
}

output "service_projects" {
  description = "Service projects details"
  value = {
    for key, project in google_project.service_projects : key => {
      project_id              = project.project_id
      name                    = project.name
      number                  = project.number
      type                    = var.service_projects[key].type
      default_service_account = data.google_compute_default_service_account.service_project_defaults[key].email
    }
  }
}

output "service_project_ids" {
  description = "Map of service project IDs"
  value = {
    for key, project in google_project.service_projects : key => project.project_id
  }
}

output "service_project_numbers" {
  description = "Map of service project numbers"
  value = {
    for key, project in google_project.service_projects : key => project.number
  }
}

# Legacy outputs for backward compatibility
output "gke_project" {
  description = "GKE project details (legacy)"
  value = try({
    project_id              = google_project.service_projects["gke"].project_id
    name                    = google_project.service_projects["gke"].name
    number                  = google_project.service_projects["gke"].number
    default_service_account = data.google_compute_default_service_account.service_project_defaults["gke"].email
  }, null)
}

output "gke_project_id" {
  description = "The ID of the GKE service project (legacy)"
  value       = try(google_project.service_projects["gke"].project_id, null)
}

output "gke_project_number" {
  description = "The project number of the GKE service project (legacy)"
  value       = try(google_project.service_projects["gke"].number, null)
}

output "data_project" {
  description = "Data project details (legacy)"
  value = try({
    project_id              = google_project.service_projects["data"].project_id
    name                    = google_project.service_projects["data"].name
    number                  = google_project.service_projects["data"].number
    default_service_account = data.google_compute_default_service_account.service_project_defaults["data"].email
  }, null)
}

output "data_project_id" {
  description = "The ID of the Data service project (legacy)"
  value       = try(google_project.service_projects["data"].project_id, null)
}

output "data_project_number" {
  description = "The project number of the Data service project (legacy)"
  value       = try(google_project.service_projects["data"].number, null)
}