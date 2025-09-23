# Create host project for Shared VPC architecture
# This project contains shared network resources
resource "google_project" "host_project" {
  name                = var.host_project.name
  project_id          = "${var.host_project.name}-${var.host_project.suffix}"
  folder_id           = var.folder_id
  billing_account     = var.billing_account_id
  auto_create_network = false
  labels              = var.labels
}

# Create service projects attached to Shared VPC
# Each project serves specific workloads (GKE, data, etc.)
resource "google_project" "service_projects" {
  for_each = var.service_projects

  name                = each.value.name
  project_id          = "${each.value.name}-${each.value.suffix}"
  billing_account     = var.billing_account_id
  folder_id           = var.folder_id
  auto_create_network = false
  labels              = var.labels
}

# Enable required APIs in host project
# Includes networking, compute, and security APIs
resource "google_project_service" "host_project_apis" {
  for_each = toset(var.host_project.apis)

  project                    = google_project.host_project.project_id
  service                    = each.value
  disable_on_destroy         = false
  disable_dependent_services = false
}

# Enable required APIs in service projects
# APIs are selected based on project type (GKE, data, etc.)
resource "google_project_service" "service_project_apis" {
  for_each = {
    for combination in flatten([
      for project_key, project in var.service_projects : [
        for api in length(project.apis) > 0 ? project.apis : var.default_apis[project.type] : {
          key        = "${project_key}-${api}"
          project_id = google_project.service_projects[project_key].project_id
          api        = api
        }
      ]
    ]) : combination.key => combination
  }

  project                    = each.value.project_id
  service                    = each.value.api
  disable_dependent_services = false
  disable_on_destroy         = false
}

# Retrieve default service accounts for service projects
# Used for resource provisioning and access management
data "google_compute_default_service_account" "service_project_defaults" {
  for_each = var.service_projects

  project    = google_project.service_projects[each.key].project_id
  depends_on = [google_project_service.service_project_apis]
}

# Enforce organization policy to disable default network creation
# Ensures all networks are explicitly defined and managed
resource "google_folder_organization_policy" "disable_default_network" {
  count      = var.disable_default_network_creation ? 1 : 0
  folder     = var.folder_id
  constraint = "compute.skipDefaultNetworkCreation"

  boolean_policy {
    enforced = true
  }
}