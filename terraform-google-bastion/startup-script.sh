#!/bin/bash

set -e
apt-get update
apt-get upgrade -y
apt-get install -y \
  fail2ban \
  htop \
  vim \
  nano \
  curl \
  wget \
  unzip \
  zip \
  jq \
  yq \
  git \
  tree \
  tmux \
  screen \
  nc \
  netcat \
  telnet \
  nmap \
  tcpdump \
  traceroute \
  dnsutils \
  net-tools \
  iproute2 \
  iptables-persistent \
  netfilter-persistent \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  openssh-client \
  rsync \
  less \
  man-db \
  bash-completion \
  sudo \
  psmisc \
  procps

echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
sysctl -p
cat > /etc/systemd/system/bastion-network-setup.service << 'EOF'
[Unit]
Description=Bastion Host Multi-Interface Network Setup
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/bastion-network-setup.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/bastion-network-setup.sh << 'EOF'
#!/bin/bash

METADATA_URL="http://metadata.google.internal/computeMetadata/v1"
echo "$(date) - Starting multi-interface network setup" >> /var/log/bastion-network.log
PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
SECONDARY_IF=$(ip link show | grep -E '^[0-9]+: ens[0-9]+' | grep -v $PRIMARY_IF | head -n1 | cut -d: -f2 | tr -d ' ')
echo "Primary interface: $PRIMARY_IF" >> /var/log/bastion-network.log
echo "Secondary interface: $SECONDARY_IF" >> /var/log/bastion-network.log
if [ -n "$SECONDARY_IF" ]; then
    # Get IP address for secondary interface from metadata
    SECONDARY_IP=$(curl -s -H "Metadata-Flavor: Google" "$METADATA_URL/instance/network-interfaces/1/ip")
    SECONDARY_GATEWAY=$(curl -s -H "Metadata-Flavor: Google" "$METADATA_URL/instance/network-interfaces/1/gateway")
    
    if [ -n "$SECONDARY_IP" ] && [ -n "$SECONDARY_GATEWAY" ]; then
        echo "Configuring secondary interface $SECONDARY_IF with IP $SECONDARY_IP" >> /var/log/bastion-network.log
        
        # Configure secondary interface IP if not already configured
        if ! ip addr show $SECONDARY_IF | grep -q $SECONDARY_IP; then
            ip addr add $SECONDARY_IP/22 dev $SECONDARY_IF 2>/dev/null || true
        fi
        
        ip link set $SECONDARY_IF up
        echo "200 data-vpc" >> /etc/iproute2/rt_tables 2>/dev/null || true
        ip route add 10.161.0.0/16 dev $SECONDARY_IF table data-vpc 2>/dev/null || true
        ip route add default via $SECONDARY_GATEWAY dev $SECONDARY_IF table data-vpc 2>/dev/null || true
        ip rule add from $SECONDARY_IP table data-vpc 2>/dev/null || true
        ip rule add to 10.161.0.0/16 table data-vpc 2>/dev/null || true
    fi
fi

iptables -F FORWARD 2>/dev/null || true
iptables -A FORWARD -i $PRIMARY_IF -o $SECONDARY_IF -j ACCEPT
iptables -A FORWARD -i $SECONDARY_IF -o $PRIMARY_IF -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -F POSTROUTING 2>/dev/null || true
iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
if [ -n "$SECONDARY_IF" ]; then
    iptables -t nat -A POSTROUTING -o $SECONDARY_IF -j MASQUERADE
fi

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables-save > /etc/iptables/rules.v4
ip route save > /etc/iptables/routes.v4 2>/dev/null || true

echo "$(date) - Multi-interface network setup completed" >> /var/log/bastion-network.log
EOF

chmod +x /usr/local/bin/bastion-network-setup.sh
systemctl enable bastion-network-setup.service
systemctl start bastion-network-setup.service

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
apt-get update && apt-get install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubectl
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update && apt-get install -y helm
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update && apt-get install -y docker-ce-cli
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform
wget -qO- https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xvz -C /tmp
mv /tmp/k9s /usr/local/bin/k9s
chmod +x /usr/local/bin/k9s
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
wget -qO /usr/local/bin/stern https://github.com/stern/stern/releases/latest/download/stern_linux_amd64
chmod +x /usr/local/bin/stern
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x /usr/local/bin/yq
wget -qO /tmp/bat.deb https://github.com/sharkdp/bat/releases/latest/download/bat_0.24.0_amd64.deb
dpkg -i /tmp/bat.deb || apt-get install -f -y
rm /tmp/bat.deb
wget -qO /tmp/fd.deb https://github.com/sharkdp/fd/releases/latest/download/fd_8.7.1_amd64.deb
dpkg -i /tmp/fd.deb || apt-get install -f -y
rm /tmp/fd.deb
wget -qO /tmp/ripgrep.deb https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep_14.0.3_amd64.deb
dpkg -i /tmp/ripgrep.deb || apt-get install -f -y
rm /tmp/ripgrep.deb
if [ "${enable_https_proxy}" = "true" ]; then
  apt-get install -y squid
  tee /etc/squid/squid.conf << 'EOF'
# Port configuration
http_port ${proxy_port}

# Allow CONNECT method for HTTPS tunneling
acl SSL_ports port 443
acl CONNECT method CONNECT

# Allow access to GKE API server and other Google APIs
acl gke_api dstdomain .googleapis.com
acl gke_api dstdomain .container.googleapis.com
acl gke_api dstdomain .gcr.io
acl gke_api dstdomain .pkg.dev

# Access rules
http_access allow CONNECT SSL_ports gke_api
http_access allow gke_api
http_access deny all

# Don't cache anything
cache deny all

# Logging for security monitoring
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
EOF

  systemctl restart squid
  systemctl enable squid

  if command -v ufw >/dev/null 2>&1; then
    ufw allow ${proxy_port}/tcp
  fi
fi

cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban
cat > /etc/ssh/sshd_config.d/bastion.conf << EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts clientspecified
PermitTunnel yes
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 20
AllowAgentForwarding yes
PermitOpen any
PermitListen any
TCPKeepAlive yes
Banner /etc/ssh/banner
EOF
cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                        AUTHORIZED ACCESS ONLY
***************************************************************************
This system is for the use of authorized users only. Individuals using
this computer system without authority, or in excess of their authority,
are subject to having all of their activities on this system monitored
and recorded by system personnel.

In the course of monitoring individuals improperly using this system, or
in the course of system maintenance, the activities of authorized users
may also be monitored.

Anyone using this system expressly consents to such monitoring and is
advised that if such monitoring reveals possible evidence of criminal
activity, system personnel may provide the evidence to law enforcement.
***************************************************************************
EOF

systemctl restart ssh
cat > /etc/rsyslog.d/bastion.conf << EOF
# Bastion host logging configuration
auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
kern.*                          -/var/log/kern.log
mail.*                          -/var/log/mail.log
cron.*                          /var/log/cron.log
*.emerg                         :omusrmsg:*
EOF

systemctl restart rsyslog
cat > /etc/logrotate.d/bastion << EOF
/var/log/auth.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}

/var/log/bastion-*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF

cat > /usr/local/bin/bastion-monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/bastion-access.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Log successful SSH connections
if [ -n "$SSH_CLIENT" ]; then
    echo "$DATE - SSH access from $SSH_CLIENT by user $USER" >> $LOG_FILE
fi

# Log command execution (for audit purposes)
if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
    echo "$DATE - Command executed by $USER: $SSH_ORIGINAL_COMMAND" >> $LOG_FILE
fi
EOF

chmod +x /usr/local/bin/bastion-monitor.sh
groupadd -f bastion-users
cat > /etc/audit/rules.d/bastion.rules << EOF
# Bastion host audit rules
-w /etc/ssh/sshd_config -p wa -k ssh_config
-w /etc/ssh/sshd_config.d/ -p wa -k ssh_config
-w /var/log/auth.log -p wa -k auth_log
-w /home -p wa -k home_dir
-w /usr/local/bin -p wa -k local_binaries
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d -p wa -k sudoers
EOF

if command -v auditd >/dev/null 2>&1; then
    systemctl enable auditd
    systemctl start auditd
fi

if command -v ufw >/dev/null 2>&1; then
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow ${proxy_port}/tcp 
fi

cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\$${distro_id}:\$${distro_codename}-security";
    "\$${distro_id}ESMApps:\$${distro_codename}-apps-security";
    "\$${distro_id}ESM:\$${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "root";
Unattended-Upgrade::MailReport "on-change";
EOF

apt-get install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

cat > /etc/profile.d/bastion-aliases.sh << 'EOF'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias k='kubectl'
alias kctx='kubectx'
alias kns='kubens'
alias tf='terraform'
alias cat='bat'
alias find='fd'
alias grep='rg'
source <(kubectl completion bash)
complete -F __start_kubectl k
source <(helm completion bash)
complete -C /usr/bin/terraform terraform
complete -C /usr/bin/terraform tf
alias gs='git status'
alias gl='git log --oneline'
alias gd='git diff'
alias ports='netstat -tulanp'
alias listen='ss -tuln'
alias route='ip route'
export PS1='\[\033[01;31m\][BASTION]\[\033[00m\] \[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
cat > /etc/update-motd.d/99-bastion-welcome << 'EOF'
#!/bin/bash
echo "=========================================="
echo "Welcome to fintech Bastion Host"
echo "=========================================="
echo "This is a secured jump host for accessing"
echo "private resources in the fintech infrastructure."
echo ""
echo "Available tools:"
echo "  • kubectl, helm, k9s (Kubernetes)"
echo "  • gcloud (Google Cloud)"
echo "  • terraform (Infrastructure)"
echo "  • docker (Container operations)"
echo "  • git, jq, yq (Development)"
echo "  • networking tools (nmap, tcpdump, etc.)"
echo ""
echo "Access is restricted and all activities are logged."
echo "=========================================="
EOF

chmod +x /etc/update-motd.d/99-bastion-welcome
cat > /usr/local/bin/bastion-info.sh << 'EOF'
#!/bin/bash
echo "=== Bastion Host System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo "Kernel: $(uname -r)"
echo "OS: $(lsb_release -d | cut -f2)"
echo ""
echo "=== Network Interfaces ==="
ip addr show | grep -E '^[0-9]+:|inet '
echo ""
echo "=== Routing Tables ==="
echo "Main table:"
ip route show
echo ""
echo "Data VPC table:"
ip route show table data-vpc 2>/dev/null || echo "No data-vpc table found"
echo ""
echo "=== Active Services ==="
systemctl is-active ssh squid fail2ban auditd bastion-network-setup
echo ""
echo "=== Disk Usage ==="
df -h /
echo ""
echo "=== Tool Versions ==="
echo "kubectl: $(kubectl version --client --short 2>/dev/null)"
echo "gcloud: $(gcloud version --format='value(Google Cloud SDK)')"
echo "terraform: $(terraform version -json | jq -r .terraform_version)"
echo "helm: $(helm version --short)"
echo "docker: $(docker --version)"
echo "git: $(git --version)"
EOF

chmod +x /usr/local/bin/bastion-info.sh
echo "$(date) - Bastion host startup script completed successfully" >> /var/log/bastion-startup.log
echo "$(date) - Enhanced tools installed: kubectl, gcloud, terraform, helm, k9s, docker-cli, and utilities" >> /var/log/bastion-startup.log
curl -X POST "https://logging.googleapis.com/v1/entries:write" \
  -H "Authorization: Bearer $(curl -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token | jq -r .access_token)" \
  -H "Content-Type: application/json" \
  -d "{
    'logName': 'projects/${project_id}/logs/bastion-host',
    'resource': {
      'type': 'gce_instance',
      'labels': {
        'instance_id': '$(curl -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/id)',
        'zone': '$(curl -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)',
        'project_id': '${project_id}'
      }
    },
    'entries': [{
      'severity': 'INFO',
      'textPayload': 'Enhanced bastion host startup completed with comprehensive toolset'
    }]
  }" 2>/dev/null || true

echo "Bastion host setup completed successfully!"
echo "Run 'bastion-info.sh' to see system status and available tools."