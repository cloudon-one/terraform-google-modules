# Terraform Google Bastion Host Module

This Terraform module creates a secured jump host (bastion host) in Google Cloud Platform for accessing private resources in your infrastructure.

## Features

- **Secure SSH Access**: Configures SSH with key-based authentication only
- **IAP Tunnel Support**: Enables Identity-Aware Proxy tunnel access for enhanced security
- **Network Security**: Implements firewall rules to restrict access to authorized networks
- **Monitoring & Logging**: Comprehensive logging and monitoring of all access
- **Fail2ban Protection**: Automatic protection against brute force attacks
- **Audit Trail**: Complete audit logging of all activities
- **Automatic Updates**: Unattended security updates
- **Deletion Protection**: Prevents accidental deletion of the bastion host
- **Cloud NAT Support**: Optional Cloud Router and NAT for outbound internet access

## Usage

```hcl
module "bastion" {
  source = "../modules/terraform-google-bastion"

  project_id = "host-project"
  region     = "us-central1"
  zone       = "a"
  
  vpc_name   = "shared-vpc"
  subnet_name = "bastion-subnet"
  
  authorized_networks = [
    "10.160.0.0/16",    # gke-vpc
    "10.161.0.0/16",    # data-vpc
    "10.100.0.0/22"    # vpn-network
  ]
  
  ssh_keys = {
    "admin" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
    "user1" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
  }
  
  enable_iap_tunnel = true
  iap_user         = "admin@fintech.com"
  
  # Optional: Enable OS Login for IAM-based SSH access
  enable_os_login = true
  os_login_users = [
    "user:admin@fintech.com",
    "user:dev@fintech.com",
  ]
  
  # Optional: Enable an HTTPS proxy on the bastion
  enable_https_proxy = true
  proxy_port = 3128
  proxy_source_ranges = [
    "10.160.0.0/16", # gke-vpc
    "10.161.0.0/16", # data-vpc
  ]
  
  # Optional: Enable NAT for outbound internet access
  enable_nat = true
  router_name = "bastion-router"
  
  name_prefix = "fintech"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | ~> 5.0 |
| google-beta | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 5.0 |
| google-beta | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | The ID of the project where the bastion host will be created | `string` | n/a | yes |
| region | The region where the bastion host will be created | `string` | n/a | yes |
| zone | The zone where the bastion host will be created (a, b, c, etc.) | `string` | `"a"` | no |
| vpc_name | The name of the VPC where the bastion host will be deployed | `string` | n/a | yes |
| subnet_name | The name of the subnet where the bastion host will be deployed | `string` | n/a | yes |
| name_prefix | Prefix for resource names | `string` | `"fintech"` | no |
| service_account_name | Name for the bastion host service account | `string` | `"bastion-host"` | no |
| machine_type | The machine type for the bastion host | `string` | `"e2-micro"` | no |
| boot_image | The boot image for the bastion host | `string` | `"debian-cloud/debian-11"` | no |
| boot_disk_size_gb | The size of the boot disk in GB | `number` | `20` | no |
| boot_disk_type | The type of the boot disk | `string` | `"pd-standard"` | no |
| authorized_networks | List of authorized network CIDR blocks for SSH access | `list(string)` | `[]` | no |
| ssh_keys | Map of SSH public keys for user access | `map(string)` | `{}` | no |
| enable_iap_tunnel | Enable IAP tunnel access to the bastion host | `bool` | `true` | no |
| iap_user | The user email for IAP tunnel access | `string` | `""` | no |
| enable_os_login | Enable OS Login for centralized SSH access management | `bool` | `false` | no |
| os_login_users | List of IAM users to grant OS Login access | `list(string)` | `[]` | no |
| enable_https_proxy | Enable Squid HTTPS proxy on the bastion host | `bool` | `false` | no |
| proxy_port | The port for the HTTPS proxy to listen on | `number` | `3128` | no |
| proxy_source_ranges | List of CIDR blocks allowed to use the HTTPS proxy | `list(string)` | `[]` | no |
| enable_nat | Enable Cloud NAT for outbound internet access | `bool` | `false` | no |
| router_name | The name of the Cloud Router for NAT configuration | `string` | `"bastion-router"` | no |
| deletion_protection | Enable deletion protection for the bastion host | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| bastion_instance_name | The name of the bastion host instance |
| bastion_instance_id | The ID of the bastion host instance |
| bastion_instance_self_link | The self-link of the bastion host instance |
| bastion_external_ip | The external IP address of the bastion host |
| bastion_internal_ip | The internal IP address of the bastion host |
| bastion_service_account_email | The email of the bastion host service account |
| bastion_service_account_name | The name of the bastion host service account |
| bastion_zone | The zone where the bastion host is deployed |
| bastion_ssh_command | SSH command to connect to the bastion host |
| bastion_iap_command | IAP tunnel command to connect to the bastion host |
| bastion_router_name | The name of the Cloud Router created for the bastion host |
| bastion_nat_name | The name of the Cloud NAT created for the bastion host |

## Pre-installed Tools
The bastion host comes pre-installed with the following tools to facilitate cluster management:
- `google-cloud-sdk` (gcloud, gsutil, etc.)
- `kubectl`

## Security Features

### SSH Configuration
- Key-based authentication only (no passwords)
- Root login disabled
- X11 forwarding disabled
- TCP forwarding enabled for tunneling
- Connection timeouts configured
- Maximum authentication attempts limited

### Network Security

- Firewall rules restrict access to authorized networks
- IAP tunnel support for secure access without public IP exposure
- Network tags for fine-grained firewall control
- Optional Cloud NAT for controlled outbound access

### Monitoring & Logging

- All SSH connections logged
- Command execution audit trail
- Fail2ban protection against brute force attacks
- Cloud Logging integration
- Log rotation and retention policies

### System Security

- Automatic security updates
- Unattended upgrades enabled
- Audit logging configured
- Firewall (UFW) enabled if available

### OS Login

- **IAP Tunnel**: Secure access without public IP exposure
- **OS Login**: Centralized SSH access control via IAM

### HTTPS Proxy

- **Squid Proxy**: Provides controlled internet access for internal resources.
- **Network-Based Access**: Access to the proxy is restricted to the CIDR blocks defined in `proxy_source_ranges`.

## Access Methods

### 1. Direct SSH (if authorized networks configured)

```bash
gcloud compute ssh fintech-bastion --zone=us-central1-a --project=host-project
```

### 2. IAP Tunnel (recommended)
```bash
# Start IAP tunnel
gcloud compute start-iap-tunnel fintech-bastion 22 --local-host-port=localhost:2222 --zone=us-central1-a --project=host-project

# Connect via tunnel
ssh -p 2222 user@localhost
```

### 3. Using the output commands
```bash
# Get the SSH command
terraform output bastion_ssh_command

# Get the IAP tunnel command
terraform output bastion_iap_command
```

### 4. Connecting with OS Login
When OS Login is enabled, you can connect using the `gcloud compute ssh` command, and access is determined by IAM roles.
```bash
gcloud compute ssh [USERNAME]@[INSTANCE_NAME] --project=[PROJECT_ID] --zone=[ZONE]
```

## HTTPS Proxy Configuration
When `enable_https_proxy` is set to `true`, the module will:
1.  **Install Squid**: The Squid proxy server is installed on the bastion host.
2.  **Configure Access**: A firewall rule is created to allow traffic to the `proxy_port` from the IP ranges specified in `proxy_source_ranges`.
3. **Secure Access**: The Squid configuration (`squid.conf`) is dynamically generated to only allow requests from the `proxy_source_ranges`.

### Using the Proxy
To use the proxy, configure your applications or system environment variables on your internal instances:
```bash
export HTTPS_PROXY="http://[BASTION_INTERNAL_IP]:[PROXY_PORT]"
export HTTP_PROXY="http://[BASTION_INTERNAL_IP]:[PROXY_PORT]"
export NO_PROXY="localhost,127.0.0.1,metadata.google.internal"
```

## Cloud NAT Configuration

When `enable_nat = true`, the module will:

1. **Create a Cloud Router** with the specified `router_name`
2. **Create a Cloud NAT** for outbound internet access
3. **Configure NAT** to allow all subnets in the VPC to access the internet

### NAT Configuration Example
```hcl
module "bastion" {
  # ... other configuration ...
  
  enable_nat = true
  router_name = "fintech-bastion-router"
}
```

### Router and NAT Outputs
```bash
# Get router name
terraform output bastion_router_name

# Get NAT name
terraform output bastion_nat_name
```

## Best Practices

1. **Use IAP Tunnel**: Prefer IAP tunnel access over direct SSH for enhanced security
2. **Restrict Networks**: Only allow access from authorized corporate networks
3. **Rotate Keys**: Regularly rotate SSH keys for all users
4. **Monitor Access**: Review access logs regularly
5. **Update Regularly**: Keep the bastion host updated with security patches
6. **Backup Configuration**: Backup SSH keys and configuration
7. **Use Strong Keys**: Use strong SSH keys (RSA 4096 or Ed25519)
8. **NAT Usage**: Only enable NAT if outbound internet access is required

## Troubleshooting

### Common Issues

1. **SSH Connection Refused**
   - Check firewall rules
   - Verify authorized networks
   - Ensure IAP tunnel is running (if using IAP)

2. **Permission Denied**
   - Verify SSH key is added to the instance
   - Check user permissions
   - Ensure key format is correct

3. **IAP Tunnel Issues**
   - Verify IAP API is enabled
   - Check user has IAP tunnel access role
   - Ensure correct project and zone

4. **OS Login Issues**
   - Verify the user has the `roles/compute.osLogin` IAM role.
   - Ensure that the project has OS Login enabled in metadata.
   - Use `gcloud compute os-login describe-profile` to check a user's POSIX account information.

5. **Proxy Connection Issues**
   - Verify that the `proxy_source_ranges` in your configuration correctly includes the IP address of the client instance.
   - Check that the bastion's firewall rule for the proxy port is active and correctly configured.
   - From the client instance, try to connect to the proxy port using `telnet [BASTION_INTERNAL_IP] [PROXY_PORT]`.

6. **Instance Not Starting**
   - Check instance logs
   - Verify startup script execution
   - Check resource quotas

7. **NAT Issues**
   - Verify router was created successfully
   - Check NAT configuration
   - Ensure proper IAM permissions

### Log Locations
- SSH logs: `/var/log/auth.log`
- Bastion access logs: `/var/log/bastion-access.log`
- Fail2ban logs: `/var/log/fail2ban.log`
- Cloud Logging: `projects/-host-project/logs/bastion-host`
- Squid logs: `/var/log/squid/access.log` and `/var/log/squid/cache.log` on the bastion host.

## License

This module is licensed under the MIT License. See LICENSE file for details. 