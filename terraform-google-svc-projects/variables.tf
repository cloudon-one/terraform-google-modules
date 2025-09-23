variable "folder_id" {
  description = "Folder ID where projects will be created"
  type        = string
}

variable "billing_account_id" {
  description = "Billing account ID"
  type        = string
}

variable "labels" {
  description = "Labels to apply to projects"
  type        = map(string)
  default     = {}
}

variable "host_project" {
  description = "Host project configuration"
  type = object({
    name   = string
    suffix = string
    apis = optional(list(string), [
      "compute.googleapis.com",
      "container.googleapis.com",
      "servicenetworking.googleapis.com",
      "cloudresourcemanager.googleapis.com",
      "dns.googleapis.com"
    ])
  })
}

variable "service_projects" {
  description = "Map of service projects to create"
  type = map(object({
    name   = string
    suffix = string
    type   = string # "gke" or "data"
    apis   = optional(list(string), [])
  }))
  default = {}
}

variable "default_apis" {
  description = "Default APIs for different project types"
  type        = map(list(string))
  default = {
    gke = [
      "container.googleapis.com",
      "compute.googleapis.com",
      "monitoring.googleapis.com",
      "logging.googleapis.com",
      "cloudtrace.googleapis.com"
    ]
    data = [
      "compute.googleapis.com",
      "dataflow.googleapis.com",
      "composer.googleapis.com",
      "bigquery.googleapis.com",
      "storage.googleapis.com",
      "sql-component.googleapis.com",
      "sqladmin.googleapis.com",
      "pubsub.googleapis.com",
      "dataproc.googleapis.com"
    ]
  }
}

variable "disable_default_network_creation" {
  description = "Whether to disable default network creation at folder level"
  type        = bool
  default     = true
}