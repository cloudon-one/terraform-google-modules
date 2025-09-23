# Create Access Context Manager policy for VPC Service Controls
# Foundation for defining access levels and service perimeters
resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.organization_id}"
  title  = "fintech Production Access Policy"
}

# Define access levels for different teams and service accounts
# Controls who can access resources within service perimeters
resource "google_access_context_manager_access_levels" "access_levels" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"

  # Create access level for DevOps team members
  # Grants administrative access to infrastructure resources
  dynamic "access_levels" {
    for_each = length(var.devops_team_members) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/devops_team"
      title = "fintech DevOps Team"
      basic {
        conditions {
          members = var.devops_team_members
        }
      }
    }
  }

  dynamic "access_levels" {
    for_each = length(var.backend_team_members) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/backend_team"
      title = "fintech Backend Team"
      basic {
        conditions {
          members = var.backend_team_members
        }
      }
    }
  }

  dynamic "access_levels" {
    for_each = length(var.frontend_team_members) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/frontend_team"
      title = "fintech Frontend Team"
      basic {
        conditions {
          members = var.frontend_team_members
        }
      }
    }
  }

  dynamic "access_levels" {
    for_each = length(var.mobile_team_members) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/mobile_team"
      title = "fintech Mobile Team"
      basic {
        conditions {
          members = var.mobile_team_members
        }
      }
    }
  }

  # Create access level for service accounts
  # Enables automated service-to-service communication
  dynamic "access_levels" {
    for_each = length(var.service_accounts) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/service_accounts"
      title = "fintech Service Accounts"
      basic {
        conditions {
          members = var.service_accounts
        }
      }
    }
  }

  # Create access level for GKE Workload Identity service accounts
  # Allows Kubernetes pods to access GCP resources securely
  dynamic "access_levels" {
    for_each = length(var.gke_workload_identity_service_accounts) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/gke_workload_identity"
      title = "GKE Workload Identity Service Accounts"
      basic {
        conditions {
          members = var.gke_workload_identity_service_accounts
        }
      }
    }
  }

  # Create access level for IAP tunnel users
  # Enables secure administrative access through Identity-Aware Proxy
  dynamic "access_levels" {
    for_each = length(var.iap_tunnel_users) > 0 ? [1] : []
    content {
      name  = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/iap_tunnel_users"
      title = "IAP Tunnel Users"
      basic {
        conditions {
          members = var.iap_tunnel_users
        }
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "main_perimeter" {
  parent         = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name           = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/fintech_prod_main_perimeter"
  title          = "fintech Production Main Perimeter"
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  status {
    resources = [
      "projects/${var.host_project_id}",
      "projects/${var.gke_project_id}",
      "projects/${var.data_project_id}"
    ]

    restricted_services = var.restricted_services

    dynamic "ingress_policies" {
      for_each = length(var.devops_team_members) > 0 ? [1] : []
      content {
        ingress_from {
          identity_type = "ANY_IDENTITY"
          sources {
            access_level = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/devops_team"
          }
        }
        ingress_to {
          resources = ["*"]
          operations {
            service_name = "*"
            method_selectors {
              method = "*"
            }
          }
        }
      }
    }

    egress_policies {
      egress_from {
        identity_type = "ANY_IDENTITY"
      }
      egress_to {
        resources = ["*"]
        operations {
          service_name = "*"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
}

resource "google_access_context_manager_service_perimeter" "bridge_perimeter" {
  parent         = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name           = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/fintech_prod_bridge_perimeter"
  title          = "fintech Production Bridge Perimeter"
  perimeter_type = "PERIMETER_TYPE_BRIDGE"

  status {
    resources = [
      "projects/${var.host_project_id}",
      "projects/${var.gke_project_id}",
      "projects/${var.data_project_id}"
    ]

    restricted_services = var.bridge_services
  }
}

resource "google_access_context_manager_service_perimeter" "vpc_sc_perimeter" {
  parent         = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name           = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/fintech_prod_vpc_sc_perimeter"
  title          = "fintech Production VPC SC Perimeter"
  perimeter_type = "PERIMETER_TYPE_REGULAR"

  status {
    resources = [
      "projects/${var.host_project_id}",
      "projects/${var.gke_project_id}",
      "projects/${var.data_project_id}"
    ]

    restricted_services = var.vpc_restricted_services

    dynamic "ingress_policies" {
      for_each = length(var.devops_team_members) > 0 ? [1] : []
      content {
        ingress_from {
          identity_type = "ANY_IDENTITY"
          sources {
            access_level = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/devops_team"
          }
        }
        ingress_to {
          resources = ["*"]
          operations {
            service_name = "compute.googleapis.com"
            method_selectors {
              method = "*"
            }
          }
        }
      }
    }

    dynamic "ingress_policies" {
      for_each = length(var.service_accounts) > 0 ? [1] : []
      content {
        ingress_from {
          identity_type = "ANY_IDENTITY"
          sources {
            access_level = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/service_accounts"
          }
        }
        ingress_to {
          resources = ["*"]
          operations {
            service_name = "container.googleapis.com"
            method_selectors {
              method = "*"
            }
          }
        }
      }
    }

    dynamic "ingress_policies" {
      for_each = length(var.service_accounts) > 0 ? [1] : []
      content {
        ingress_from {
          identity_type = "ANY_IDENTITY"
          sources {
            access_level = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/service_accounts"
          }
        }
        ingress_to {
          resources = ["*"]
          operations {
            service_name = "sqladmin.googleapis.com"
            method_selectors {
              method = "*"
            }
          }
        }
      }
    }

    dynamic "ingress_policies" {
      for_each = length(var.service_accounts) > 0 ? [1] : []
      content {
        ingress_from {
          identity_type = "ANY_IDENTITY"
          sources {
            access_level = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/service_accounts"
          }
        }
        ingress_to {
          resources = ["*"]
          operations {
            service_name = "redis.googleapis.com"
            method_selectors {
              method = "*"
            }
          }
        }
      }
    }

    egress_policies {
      egress_from {
        identity_type = "ANY_IDENTITY"
      }
      egress_to {
        resources = ["*"]
        operations {
          service_name = "*"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
} 