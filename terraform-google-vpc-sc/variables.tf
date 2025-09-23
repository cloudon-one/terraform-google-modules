variable "organization_id" {
  description = "The organization ID where the VPC SC policy will be created"
  type        = string
}

variable "host_project_id" {
  description = "The host project ID for the VPC SC perimeter"
  type        = string
}

variable "gke_project_id" {
  description = "The GKE project ID to be included in the VPC SC perimeter"
  type        = string
}

variable "data_project_id" {
  description = "The data project ID to be included in the VPC SC perimeter"
  type        = string
}

variable "devops_team_members" {
  description = "List of DevOps team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "backend_team_members" {
  description = "List of backend team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "frontend_team_members" {
  description = "List of frontend team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "mobile_team_members" {
  description = "List of mobile team members (users and service accounts)"
  type        = list(string)
  default     = []
}

variable "service_accounts" {
  description = "List of service accounts for access control"
  type        = list(string)
  default     = []
}

variable "gke_workload_identity_service_accounts" {
  description = "List of GKE workload identity service accounts"
  type        = list(string)
  default     = []
}

variable "iap_tunnel_users" {
  description = "List of IAP tunnel users"
  type        = list(string)
  default     = []
}

variable "restricted_services" {
  description = "List of restricted services for the main perimeter"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "bigtable.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dataflow.googleapis.com",
    "composer.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "pubsub.googleapis.com",
    "dataproc.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "errorreporting.googleapis.com",
    "clouddebugger.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "containerregistry.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "workflows.googleapis.com",
    "datacatalog.googleapis.com",
    "datalabeling.googleapis.com",
    "aiplatform.googleapis.com",
    "ml.googleapis.com",
    "notebooks.googleapis.com",
    "dataprep.googleapis.com",
    "datafusion.googleapis.com",
    "datastream.googleapis.com",
    "spanner.googleapis.com",
    "firestore.googleapis.com",
    "firebase.googleapis.com",
    "identitytoolkit.googleapis.com",
    "iap.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containeranalysis.googleapis.com",
    "ondemandscanning.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "billing.googleapis.com",
    "cloudbilling.googleapis.com",
    "recommender.googleapis.com",
    "policyanalyzer.googleapis.com",
    "assuredworkloads.googleapis.com",
    "accesscontextmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networksecurity.googleapis.com",
    "networkmanagement.googleapis.com"
  ]
}

variable "bridge_services" {
  description = "List of services for the bridge perimeter"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "pubsub.googleapis.com",
    "dataproc.googleapis.com",
    "dataflow.googleapis.com",
    "composer.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "workflows.googleapis.com"
  ]
}

variable "vpc_restricted_services" {
  description = "List of VPC-specific restricted services"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "networkconnectivity.googleapis.com",
    "networksecurity.googleapis.com",
    "networkmanagement.googleapis.com"
  ]
} 