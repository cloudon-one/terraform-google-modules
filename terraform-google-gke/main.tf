# Create GKE cluster with enterprise security features
# Implements private cluster with workload identity and encryption
resource "google_container_cluster" "primary" {
  name                        = var.cluster_name
  location                    = var.region
  project                     = var.project_id
  network                     = var.network
  subnetwork                  = var.subnetwork
  description                 = "Managed by Terraform"
  remove_default_node_pool    = false
  initial_node_count          = 1
  enable_l4_ilb_subsetting    = true
  enable_intranode_visibility = var.enable_intranode_visibility
  datapath_provider           = var.datapath_provider
  resource_labels             = var.resource_labels

  # Configure private cluster for enhanced security
  # Nodes have only private IPs, control plane optionally public
  private_cluster_config {
    enable_private_nodes        = true
    enable_private_endpoint     = var.enable_private_endpoint
    private_endpoint_subnetwork = var.private_endpoint_subnetwork
    master_global_access_config {
      enabled = var.enable_master_global_access
    }
  }

  # Restrict control plane access to authorized networks
  # Enhances security by limiting API server exposure
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = var.enable_gcp_public_cidrs_access
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Configure IP ranges for pods and services
  # Uses secondary ranges for proper network isolation
  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_allocation_policy.cluster_secondary_range_name
    services_secondary_range_name = var.ip_allocation_policy.services_secondary_range_name
    cluster_ipv4_cidr_block       = var.ip_allocation_policy.cluster_ipv4_cidr_block
    services_ipv4_cidr_block      = var.ip_allocation_policy.services_ipv4_cidr_block
    pod_cidr_overprovision_config {
      disabled = false
    }
  }

  release_channel {
    channel = var.release_channel
  }

  # Enable Workload Identity for secure pod authentication
  # Allows pods to authenticate as GCP service accounts
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_fqdn_network_policy ? "CALICO" : "CALICO"
  }

  # Enable Confidential GKE Nodes for memory encryption
  # Protects data in use with hardware-based security
  confidential_nodes {
    enabled = var.confidential_nodes.enabled
  }

  dns_config {
    cluster_dns        = "CLOUD_DNS"
    cluster_dns_scope  = "CLUSTER_SCOPE"
    cluster_dns_domain = var.dns_config.cluster_dns_domain
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  default_snat_status {
    disabled = var.default_snat_status.disabled
  }
  service_external_ips_config {
    enabled = var.service_external_ips_config.enabled
  }

  vertical_pod_autoscaling {
    enabled = var.vertical_pod_autoscaling.enabled
  }

  # Configure cluster autoscaling for dynamic resource management
  # Automatically adjusts cluster size based on workload demands
  dynamic "cluster_autoscaling" {
    for_each = var.cluster_autoscaling.enabled ? [1] : []
    content {
      enabled             = true
      autoscaling_profile = var.cluster_autoscaling.autoscaling_profile

      auto_provisioning_locations = var.cluster_autoscaling.auto_provisioning_locations

      dynamic "auto_provisioning_defaults" {
        for_each = length(var.cluster_autoscaling.auto_provisioning_locations) > 0 ? [1] : []
        content {
          disk_size       = var.cluster_autoscaling.auto_provisioning_defaults.disk_size
          disk_type       = var.cluster_autoscaling.auto_provisioning_defaults.disk_type
          image_type      = var.cluster_autoscaling.auto_provisioning_defaults.image_type
          oauth_scopes    = var.cluster_autoscaling.auto_provisioning_defaults.oauth_scopes
          service_account = var.cluster_autoscaling.auto_provisioning_defaults.service_account

          management {
            auto_repair  = var.cluster_autoscaling.auto_provisioning_defaults.management.auto_repair
            auto_upgrade = var.cluster_autoscaling.auto_provisioning_defaults.management.auto_upgrade
          }

          shielded_instance_config {
            enable_integrity_monitoring = var.cluster_autoscaling.auto_provisioning_defaults.shielded_instance_config.enable_integrity_monitoring
            enable_secure_boot          = var.cluster_autoscaling.auto_provisioning_defaults.shielded_instance_config.enable_secure_boot
          }
        }
      }

      dynamic "resource_limits" {
        for_each = var.cluster_autoscaling.resource_limits
        content {
          resource_type = resource_limits.value.resource_type
          minimum       = resource_limits.value.minimum
          maximum       = resource_limits.value.maximum
        }
      }
    }
  }

  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
    dns_cache_config {
      enabled = var.addons_config.dns_cache_config.enabled
    }
    gce_persistent_disk_csi_driver_config {
      enabled = var.addons_config.gce_persistent_disk_csi_driver_config.enabled
    }
    gcp_filestore_csi_driver_config {
      enabled = var.addons_config.gcp_filestore_csi_driver_config.enabled
    }
    gcs_fuse_csi_driver_config {
      enabled = var.addons_config.gcs_fuse_csi_driver_config.enabled
    }
    gke_backup_agent_config {
      enabled = var.addons_config.gke_backup_agent_config.enabled
    }
    network_policy_config {
      disabled = var.addons_config.network_policy_config.disabled
    }
    config_connector_config {
      enabled = var.enable_secret_manager
    }
    ray_operator_config {
      enabled = var.addons_config.ray_operator_config.enabled

      ray_cluster_logging_config {
        enabled = var.addons_config.ray_operator_config.ray_cluster_logging_config.enabled
      }

      ray_cluster_monitoring_config {
        enabled = var.addons_config.ray_operator_config.ray_cluster_monitoring_config.enabled
      }
    }
    stateful_ha_config {
      enabled = var.addons_config.stateful_ha_config.enabled
    }
  }

  maintenance_policy {
    dynamic "daily_maintenance_window" {
      for_each = var.maintenance_window.daily_window_start_time != null ? [1] : []
      content {
        start_time = var.maintenance_window.daily_window_start_time
      }
    }
    dynamic "recurring_window" {
      for_each = var.maintenance_window.recurring_window != null ? [1] : []
      content {
        start_time = var.maintenance_window.recurring_window.start_time
        end_time   = var.maintenance_window.recurring_window.end_time
        recurrence = var.maintenance_window.recurring_window.recurrence
      }
    }
  }

  monitoring_config {
    enable_components = var.monitoring.enable_components
    managed_prometheus {
      enabled = var.monitoring.enable_managed_prometheus
    }
    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = true
    }
  }

  logging_config {
    enable_components = var.logging.enable_components
  }

  deletion_protection = var.deletion_protection

  database_encryption {
    state    = var.database_encryption.state
    key_name = var.database_encryption.state == "ENCRYPTED" ? var.database_encryption.key_name : null
  }

  security_posture_config {
    mode               = var.security_posture_config.mode
    vulnerability_mode = var.security_posture_config.vulnerability_mode
  }

  cost_management_config {
    enabled = var.cost_management_config.enabled
  }

  notification_config {
    pubsub {
      enabled = var.notification_config.pubsub.enabled
      topic   = var.notification_config.pubsub.topic
    }
  }
  node_pool_auto_config {
    resource_manager_tags = var.node_pool_auto_config.resource_manager_tags

    network_tags {
      tags = var.node_pool_auto_config.network_tags.tags
    }

    node_kubelet_config {
      insecure_kubelet_readonly_port_enabled = var.node_pool_auto_config.node_kubelet_config.insecure_kubelet_readonly_port_enabled
    }
  }

  node_pool_defaults {
    node_config_defaults {
      insecure_kubelet_readonly_port_enabled = var.node_pool_defaults.node_config_defaults.insecure_kubelet_readonly_port_enabled
      logging_variant                        = var.node_pool_defaults.node_config_defaults.logging_variant
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = var.master_auth.client_certificate_config.issue_client_certificate
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = var.authenticator_groups_config.security_group != "" ? [1] : []
    content {
      security_group = var.authenticator_groups_config.security_group
    }
  }

  mesh_certificates {
    enable_certificates = var.mesh_certificates.enable_certificates
  }

  identity_service_config {
    enabled = var.identity_service_config.enabled
  }

  binary_authorization {
    evaluation_mode = var.binary_authorization.evaluation_mode
  }

  node_config {
    machine_type = "n2d-standard-2"
    disk_size_gb = 100
    disk_type    = "pd-balanced"
    oauth_scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    confidential_nodes {
      enabled = true
    }
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }
  }

  lifecycle {
    ignore_changes = [
      dns_config,
      authenticator_groups_config,
      identity_service_config,
      mesh_certificates,
      master_auth,
      remove_default_node_pool,
      resource_labels,
      network_policy
    ]
  }
}

resource "google_container_node_pool" "node_pools" {
  for_each = var.node_pools

  name       = each.value.name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = each.value.node_count
  project    = var.project_id
  version    = each.value.version

  node_locations    = each.value.node_locations
  max_pods_per_node = each.value.max_pods_per_node

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type

    service_account = var.create_service_account ? google_service_account.gke_service_account[0].email : each.value.service_account

    oauth_scopes = each.value.oauth_scopes

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = merge(
      each.value.labels,
      var.labels
    )

    tags = each.value.tags

    metadata          = each.value.metadata
    resource_labels   = each.value.resource_labels
    boot_disk_kms_key = each.value.boot_disk_kms_key
    confidential_nodes {
      enabled = each.value.confidential_nodes.enabled
    }
    shielded_instance_config {
      enable_integrity_monitoring = each.value.shielded_instance_config.enable_integrity_monitoring
      enable_secure_boot          = each.value.shielded_instance_config.enable_secure_boot
    }

    advanced_machine_features {
      enable_nested_virtualization = each.value.advanced_machine_features.enable_nested_virtualization
      threads_per_core             = each.value.advanced_machine_features.threads_per_core
    }

    kubelet_config {
      cpu_cfs_quota                          = each.value.kubelet_config.cpu_cfs_quota
      insecure_kubelet_readonly_port_enabled = each.value.kubelet_config.insecure_kubelet_readonly_port_enabled
      pod_pids_limit                         = each.value.kubelet_config.pod_pids_limit
      cpu_manager_policy                     = each.value.kubelet_config.cpu_manager_policy
    }

    enable_confidential_storage = each.value.enable_confidential_storage
    logging_variant             = each.value.logging_variant
    local_ssd_count             = each.value.local_ssd_count
    dynamic "guest_accelerator" {
      for_each = each.value.guest_accelerator
      content {
        count = guest_accelerator.value.count
        type  = guest_accelerator.value.type
      }
    }

    image_type            = each.value.image_type
    preemptible           = each.value.preemptible
    spot                  = each.value.spot
    resource_manager_tags = each.value.resource_manager_tags

    dynamic "gcfs_config" {
      for_each = each.value.gcfs_config != null ? [each.value.gcfs_config] : []
      content {
        enabled = gcfs_config.value.enabled
      }
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  autoscaling {
    min_node_count       = each.value.autoscaling.min_node_count
    max_node_count       = each.value.autoscaling.max_node_count
    location_policy      = each.value.autoscaling.location_policy
    total_min_node_count = each.value.autoscaling.total_min_node_count
    total_max_node_count = each.value.autoscaling.total_max_node_count
  }

  management {
    auto_repair  = each.value.management.auto_repair
    auto_upgrade = each.value.management.auto_upgrade
  }

  upgrade_settings {
    max_surge       = each.value.upgrade_settings.max_surge
    max_unavailable = each.value.upgrade_settings.max_unavailable
    strategy        = each.value.upgrade_settings.strategy
  }

  network_config {
    create_pod_range     = each.value.network_config.create_pod_range
    enable_private_nodes = each.value.network_config.enable_private_nodes
    pod_range            = each.value.network_config.pod_range
  }

  queued_provisioning {
    enabled = each.value.queued_provisioning.enabled
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    ignore_changes = [
      node_config[0].labels,
      node_config[0].resource_labels
    ]
  }
}

resource "google_service_account" "gke_service_account" {
  count = var.create_service_account ? 1 : 0

  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
  project      = var.project_id
} 