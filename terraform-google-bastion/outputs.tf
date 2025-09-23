output "bastion_instance_name" {
  description = "The name of the bastion host instance"
  value       = google_compute_instance.bastion.name
}

output "bastion_instance_id" {
  description = "The ID of the bastion host instance"
  value       = google_compute_instance.bastion.instance_id
}

output "bastion_instance_self_link" {
  description = "The self-link of the bastion host instance"
  value       = google_compute_instance.bastion.self_link
}

output "bastion_external_ip" {
  description = "The external IP address of the bastion host"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "bastion_internal_ip" {
  description = "The internal IP address of the bastion host"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "bastion_service_account_email" {
  description = "The email of the bastion host service account"
  value       = google_service_account.bastion.email
}

output "bastion_service_account_name" {
  description = "The name of the bastion host service account"
  value       = google_service_account.bastion.name
}

output "bastion_zone" {
  description = "The zone where the bastion host is deployed"
  value       = google_compute_instance.bastion.zone
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --zone=${google_compute_instance.bastion.zone} --project=${var.project_id}"
}

output "bastion_iap_command" {
  description = "IAP tunnel command to connect to the bastion host"
  value       = var.enable_iap_tunnel ? "gcloud compute start-iap-tunnel ${google_compute_instance.bastion.name} 22 --local-host-port=localhost:2222 --zone=${google_compute_instance.bastion.zone} --project=${var.project_id}" : null
}

output "bastion_router_name" {
  description = "The name of the Cloud Router created for the bastion host"
  value       = var.enable_nat ? google_compute_router.bastion_router[0].name : null
}

output "bastion_nat_name" {
  description = "The name of the Cloud NAT created for the bastion host"
  value       = var.enable_nat ? google_compute_router_nat.bastion_nat[0].name : null
} 