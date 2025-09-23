output "gke_workload_identity_service_accounts" {
  description = "GKE workload identity service account emails"
  value = {
    for k, v in google_service_account.gke_workload_identity : k => v.email
  }
}

output "cloudsql_admin_service_account_email" {
  description = "Cloud SQL admin service account email"
  value       = var.enable_sql_iam ? google_service_account.cloudsql_admin[0].email : null
}

output "cloudsql_admin_service_account_name" {
  description = "Cloud SQL admin service account name"
  value       = var.enable_sql_iam ? google_service_account.cloudsql_admin[0].name : null
}

output "cloudsql_admin_service_account_id" {
  description = "Cloud SQL admin service account ID"
  value       = var.enable_sql_iam ? google_service_account.cloudsql_admin[0].id : null
}

output "gke_service_account_email" {
  description = "GKE service account email"
  value       = var.enable_gke_iam ? google_service_account.gke_service_account[0].email : null
}

output "gke_service_account_name" {
  description = "GKE service account name"
  value       = var.enable_gke_iam ? google_service_account.gke_service_account[0].name : null
}

output "gke_service_account_id" {
  description = "GKE service account ID"
  value       = var.enable_gke_iam ? google_service_account.gke_service_account[0].id : null
}

output "iap_tunnel_users" {
  description = "List of users with IAP Tunnel access"
  value       = var.enable_iap_tunnel_iam ? var.iap_tunnel_users : []
} 