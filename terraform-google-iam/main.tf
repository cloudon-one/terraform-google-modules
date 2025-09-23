data "google_project" "gke_project" {
  count      = var.enable_gke_iam ? 1 : 0
  project_id = var.gke_project_id
}

resource "google_project_iam_member" "gke_host_service_agent" {
  count = var.enable_gke_iam ? 1 : 0

  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${data.google_project.gke_project[0].number}@container-engine-robot.iam.gserviceaccount.com"
}

resource "google_service_account" "gke_workload_identity" {
  for_each = var.enable_gke_iam ? var.gke_workload_identity_service_accounts : {}

  project      = var.gke_project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  for_each = var.enable_gke_iam ? var.gke_workload_identity_service_accounts : {}

  service_account_id = google_service_account.gke_workload_identity[each.key].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gke_project_id}.svc.id.goog[${each.value.kubernetes_namespace}/${each.value.kubernetes_service_account}]"
  ]
}

resource "google_project_iam_member" "workload_identity_roles" {
  for_each = var.enable_gke_iam ? {
    for binding in flatten([
      for sa_name, sa_config in var.gke_workload_identity_service_accounts : [
        for role in sa_config.gcp_roles : {
          sa_name = sa_name
          role    = role
        }
      ]
    ]) : "${binding.sa_name}-${binding.role}" => binding
  } : {}

  project = var.gke_project_id
  role    = each.value.role
  member  = google_service_account.gke_workload_identity[each.value.sa_name].member
}

resource "google_service_account" "cloudsql_admin" {
  count = var.enable_sql_iam ? 1 : 0

  account_id   = "cloudsql-admin"
  display_name = "Cloud SQL Admin Service Account"
  project      = var.data_project_id
}

resource "google_project_iam_member" "cloudsql_admin_role" {
  count = var.enable_sql_iam ? 1 : 0

  project = var.data_project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.cloudsql_admin[0].email}"
}

resource "google_project_iam_member" "cloudsql_client_role" {
  count = var.enable_sql_iam ? 1 : 0

  project = var.data_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_admin[0].email}"
}

resource "google_service_account" "gke_service_account" {
  count = var.enable_gke_iam ? 1 : 0

  project      = var.gke_project_id
  account_id   = var.gke_service_account_config.account_id
  display_name = var.gke_service_account_config.display_name
  description  = var.gke_service_account_config.description
}

resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = var.enable_gke_iam ? {
    for role in var.gke_service_account_config.gcp_roles : role => role
  } : {}

  project = var.gke_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account[0].email}"
}

resource "google_project_iam_member" "os_login" {
  for_each = var.enable_os_login_iam ? toset(var.os_login_users) : []
  project  = var.host_project_id
  role     = "roles/compute.osLogin"
  member   = each.value
}

resource "google_service_account" "bastion_service_account" {
  count = var.enable_bastion_iam && var.existing_bastion_service_account == "" ? 1 : 0

  project      = var.host_project_id
  account_id   = var.bastion_service_account_config.account_id
  display_name = var.bastion_service_account_config.display_name
  description  = var.bastion_service_account_config.description
}

data "google_service_account" "existing_bastion_service_account" {
  count      = var.enable_bastion_iam && var.existing_bastion_service_account != "" ? 1 : 0
  account_id = split("@", var.existing_bastion_service_account)[0]
  project    = split("@", split(".", var.existing_bastion_service_account)[0])[1]
}

locals {
  bastion_service_account_email = var.existing_bastion_service_account != "" ? var.existing_bastion_service_account : google_service_account.bastion_service_account[0].email
}

resource "google_project_iam_member" "bastion_host_project_roles" {
  for_each = var.enable_bastion_iam ? {
    for role in [
      "roles/compute.loadBalancerAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/compute.instanceAdmin",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer"
    ] : role => role
  } : {}

  project = var.host_project_id
  role    = each.value
  member  = "serviceAccount:${local.bastion_service_account_email}"
}

resource "google_project_iam_member" "bastion_gke_project_roles" {
  for_each = var.enable_bastion_iam ? {
    for role in [
      "roles/container.admin",
      "roles/container.clusterAdmin",
      "roles/container.developer",
      "roles/storage.admin",
      "roles/storage.objectAdmin",
      "roles/iam.serviceAccountUser"
    ] : role => role
  } : {}

  project = var.gke_project_id
  role    = each.value
  member  = "serviceAccount:${local.bastion_service_account_email}"
}

resource "google_project_iam_member" "bastion_data_project_roles" {
  for_each = var.enable_bastion_iam ? {
    for role in [
      "roles/cloudsql.admin",
      "roles/cloudsql.client",
      "roles/cloudsql.instanceUser",
      "roles/redis.admin",
      "roles/redis.editor",
      "roles/storage.admin",
      "roles/storage.objectAdmin"
    ] : role => role
  } : {}

  project = var.data_project_id
  role    = each.value
  member  = "serviceAccount:${local.bastion_service_account_email}"
}

resource "google_folder_iam_member" "bastion_folder_roles" {
  for_each = var.enable_bastion_iam && var.folder_id != "" ? {
    for role in [
      "roles/resourcemanager.folderViewer",
      "roles/resourcemanager.projectIamAdmin",
      "roles/resourcemanager.folderAdmin"
    ] : role => role
  } : {}

  folder = "folders/${var.folder_id}"
  role   = each.value
  member = "serviceAccount:${local.bastion_service_account_email}"
}

resource "google_project_iam_member" "iap_tunnel_user" {
  for_each = var.enable_iap_tunnel_iam ? toset(var.iap_tunnel_users) : []
  project  = var.host_project_id
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}
