variable "enable_gke_iam" {
  description = "Enable GKE IAM resources"
  type        = bool
  default     = false
}

variable "enable_sql_iam" {
  description = "Enable Cloud SQL IAM resources"
  type        = bool
  default     = false
}

variable "host_project_id" {
  description = "Host project ID for GKE"
  type        = string
  default     = ""
}

variable "gke_project_id" {
  description = "GKE project ID"
  type        = string
  default     = ""
}

variable "data_project_id" {
  description = "Data project ID for Cloud SQL"
  type        = string
  default     = ""
}

variable "gke_workload_identity_service_accounts" {
  description = "GKE workload identity service accounts configuration"
  type = map(object({
    display_name               = string
    description                = optional(string)
    kubernetes_namespace       = string
    kubernetes_service_account = string
    gcp_roles                  = list(string)
  }))
  default = {}
}

variable "gke_service_account_config" {
  description = "GKE service account configuration"
  type = object({
    account_id   = string
    display_name = string
    description  = optional(string)
    gcp_roles    = list(string)
  })
  default = {
    account_id   = "gke-service-account"
    display_name = "GKE Service Account"
    description  = "Kubernetes Engine default node service account"
    gcp_roles = [
      "roles/container.nodeServiceAccount",
      "roles/container.serviceAgent",
      "roles/container.developer",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer",
      "roles/stackdriver.resourceMetadata.writer"
    ]
  }
}

variable "enable_os_login_iam" {
  description = "Enable OS Login IAM resources"
  type        = bool
  default     = false
}

variable "os_login_users" {
  description = "List of IAM users to grant OS Login access (e.g., user:your-email@company.com)"
  type        = list(string)
  default     = []
}

variable "enable_bastion_iam" {
  description = "Enable Bastion IAM resources"
  type        = bool
  default     = false
}

variable "bastion_service_account_config" {
  description = "Bastion service account configuration"
  type = object({
    account_id   = string
    display_name = string
    description  = optional(string)
    gcp_roles    = list(string)
  })
  default = {
    account_id   = "bastion-host"
    display_name = "Bastion Host Service Account"
    description  = "Service account for bastion host with admin access to GCP resources"
    gcp_roles = [
      "roles/container.admin",
      "roles/container.clusterAdmin",
      "roles/container.developer",
      "roles/cloudsql.admin",
      "roles/cloudsql.client",
      "roles/cloudsql.instanceUser",
      "roles/storage.admin",
      "roles/storage.objectAdmin",
      "roles/redis.admin",
      "roles/redis.editor",
      "roles/compute.loadBalancerAdmin",
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/compute.instanceAdmin",
      "roles/iam.serviceAccountUser",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
      "roles/monitoring.viewer"
    ]
  }
}

variable "folder_id" {
  description = "Folder ID for folder-level IAM permissions"
  type        = string
  default     = ""
}

variable "existing_bastion_service_account" {
  description = "Existing bastion service account email to use instead of creating a new one"
  type        = string
  default     = ""
}

variable "enable_iap_tunnel_iam" {
  description = "Enable IAP Tunnel IAM resources"
  type        = bool
  default     = false
}

variable "iap_tunnel_users" {
  description = "List of IAM users to grant IAP Tunnel access (e.g., user:your-email@company.com)"
  type        = list(string)
  default     = []
} 