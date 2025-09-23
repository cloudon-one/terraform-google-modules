# Retrieve VPC network information for bastion placement
data "google_compute_network" "vpc" {
  name    = var.vpc_name
  project = var.project_id
}

# Retrieve subnet information for bastion network interface
data "google_compute_subnetwork" "subnet" {
  name    = var.subnet_name
  region  = var.region
  project = var.project_id
}

# Retrieve additional VPC networks for multi-VPC access
data "google_compute_network" "additional_vpcs" {
  count   = length(var.additional_network_interfaces)
  name    = var.additional_network_interfaces[count.index].vpc_name
  project = var.project_id
}

# Retrieve additional subnets for multi-VPC connectivity
data "google_compute_subnetwork" "additional_subnets" {
  count   = length(var.additional_network_interfaces)
  name    = var.additional_network_interfaces[count.index].subnet_name
  region  = var.region
  project = var.project_id
}

# Create service account for bastion host authentication
# Used for secure access and audit logging
resource "google_service_account" "bastion" {
  account_id   = var.service_account_name
  display_name = "Bastion Host Service Account"
  description  = "Service account for bastion host access"
  project      = var.project_id
}

# Grant logging permissions to bastion service account
# Enables audit trail for administrative access
resource "google_project_iam_member" "bastion_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Grant monitoring permissions to bastion service account
# Enables metrics collection for health monitoring
resource "google_project_iam_member" "bastion_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Configure service account impersonation permissions
# Allows authorized users to act as bastion service account
resource "google_service_account_iam_member" "bastion_sa_impersonation" {
  count              = length(var.sa_impersonators)
  service_account_id = google_service_account.bastion.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.sa_impersonators[count.index]
}

resource "google_service_account_iam_binding" "bastion_sa_users" {
  service_account_id = google_service_account.bastion.name
  role               = "roles/iam.serviceAccountUser"
  members            = var.sa_impersonators
}

# Create firewall rule for SSH access to bastion
# Restricts access to authorized networks only
resource "google_compute_firewall" "bastion_ssh" {
  name    = "${var.name_prefix}-bastion-ssh"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.authorized_networks
  target_tags   = ["bastion-host"]

  description = "Allow SSH access to bastion host from authorized networks"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create firewall rule for IAP tunnel access
# Enables secure access through Identity-Aware Proxy
resource "google_compute_firewall" "bastion_iap" {
  name    = "${var.name_prefix}-bastion-iap"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion-host"]

  description = "Allow SSH access to bastion host via IAP tunnel"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Create firewall rules for IAP access on additional VPCs
# Extends secure access across multiple networks
resource "google_compute_firewall" "bastion_iap_additional" {
  count   = length(var.additional_network_interfaces)
  name    = "${var.name_prefix}-bastion-iap-${count.index}"
  network = data.google_compute_network.additional_vpcs[count.index].name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion-host"]

  description = "Allow SSH access to bastion host via IAP tunnel on ${var.additional_network_interfaces[count.index].vpc_name}"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_https_proxy_iap" {
  count   = var.enable_https_proxy ? 1 : 0
  name    = "${var.name_prefix}-bastion-https-proxy-iap"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [var.proxy_port]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion-host"]

  description = "Allow HTTPS proxy access to bastion host via IAP tunnel"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_instance" "bastion" {
  name           = "${var.name_prefix}-bastion"
  machine_type   = var.machine_type
  zone           = "${var.region}-${var.zone}"
  project        = var.project_id
  can_ip_forward = true

  tags = ["bastion-host"]

  boot_disk {
    auto_delete = false
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet.id
    access_config {
      // Ephemeral public IP only on primary interface
    }
  }

  dynamic "network_interface" {
    for_each = var.additional_network_interfaces
    content {
      subnetwork = data.google_compute_subnetwork.additional_subnets[network_interface.key].id
    }
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = var.enable_os_login ? null : join("\n", [
      for user, key in var.ssh_keys : "${user}:${key}"
    ])
    startup-script = templatefile("${path.module}/startup-script.sh", {
      project_id              = var.project_id
      enable_https_proxy      = var.enable_https_proxy
      proxy_port              = var.proxy_port
      proxy_source_ranges_acl = join("\n", [for r in var.proxy_source_ranges : "acl localnet src ${r}"])
    })
    enable-oslogin = var.enable_os_login ? "TRUE" : "FALSE"
  }

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    project_id              = var.project_id
    enable_https_proxy      = var.enable_https_proxy
    proxy_port              = var.proxy_port
    proxy_source_ranges_acl = join("\n", [for r in var.proxy_source_ranges : "acl localnet src ${r}"])
  })

  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"]
    ]
  }
}

resource "google_iap_tunnel_instance_iam_member" "bastion_iap" {
  count    = var.enable_iap_tunnel ? 1 : 0
  project  = var.project_id
  zone     = "${var.region}-${var.zone}"
  instance = google_compute_instance.bastion.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${var.iap_user}"
}

resource "google_compute_router" "bastion_router" {
  count   = var.enable_nat ? 1 : 0
  name    = var.router_name
  region  = var.region
  network = data.google_compute_network.vpc.id
  project = var.project_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "bastion_nat" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.name_prefix}-bastion-nat"
  router  = google_compute_router.bastion_router[0].name
  region  = var.region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_project_iam_member" "os_login" {
  for_each = var.enable_os_login ? toset(var.os_login_users) : []
  project  = var.project_id
  role     = "roles/compute.osLogin"
  member   = each.value
}

resource "google_compute_firewall" "bastion_https_proxy" {
  count   = var.enable_https_proxy ? 1 : 0
  name    = "${var.name_prefix}-bastion-https-proxy"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [var.proxy_port]
  }

  source_ranges = var.proxy_source_ranges
  target_tags   = ["bastion-host"]

  description = "Allow HTTPS proxy access to bastion host from internal networks"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
resource "google_compute_firewall" "bastion_forward_gke_to_data" {
  name    = "${var.name_prefix}-bastion-forward-gke-to-data"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_tags        = ["bastion-host"]
  destination_ranges = ["10.61.0.0/16"]

  description = "Allow bastion to forward traffic from GKE to Data VPC"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_forward_data_to_gke" {
  count   = length(var.additional_network_interfaces) > 0 ? 1 : 0
  name    = "${var.name_prefix}-bastion-forward-data-to-gke"
  network = data.google_compute_network.additional_vpcs[0].name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_tags        = ["bastion-host"]
  destination_ranges = ["10.60.0.0/16"]

  description = "Allow bastion to forward traffic from Data to GKE VPC"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_internal_gke" {
  name    = "${var.name_prefix}-bastion-internal-gke"
  network = data.google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.60.0.0/16"]
  target_tags   = ["bastion-host"]

  description = "Allow internal traffic from GKE subnet to bastion"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_internal_data" {
  count   = length(var.additional_network_interfaces) > 0 ? 1 : 0
  name    = "${var.name_prefix}-bastion-internal-data"
  network = data.google_compute_network.additional_vpcs[0].name
  project = var.project_id

  allow {
    protocol = "all"
  }

  source_ranges = ["10.61.0.0/16"]
  target_tags   = ["bastion-host"]

  description = "Allow internal traffic from Data subnet to bastion"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_egress_gke" {
  name      = "${var.name_prefix}-bastion-egress-gke"
  network   = data.google_compute_network.vpc.name
  project   = var.project_id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  target_tags        = ["bastion-host"]
  destination_ranges = ["0.0.0.0/0"]

  description = "Allow all egress traffic from bastion host on GKE VPC"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "bastion_egress_data" {
  count     = length(var.additional_network_interfaces) > 0 ? 1 : 0
  name      = "${var.name_prefix}-bastion-egress-data"
  network   = data.google_compute_network.additional_vpcs[0].name
  project   = var.project_id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  target_tags        = ["bastion-host"]
  destination_ranges = ["0.0.0.0/0"]

  description = "Allow all egress traffic from bastion host on Data VPC"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
} 