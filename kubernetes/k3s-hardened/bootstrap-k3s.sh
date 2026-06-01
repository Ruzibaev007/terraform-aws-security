#!/bin/bash
# =============================================================================
# bootstrap-k3s.sh — NIS2 Hardened k3s Installation
# Runs on first boot via EC2 user_data
# =============================================================================
set -euo pipefail

CLUSTER_NAME="${cluster_name}"
ENVIRONMENT="${environment}"

echo "[NIS2] Starting k3s hardened bootstrap for $CLUSTER_NAME..."

# Update system
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
  curl unzip jq fail2ban ufw \
  auditd audispd-plugins

# =============================================================================
# NIS2 Art.32: Firewall (UFW)
# =============================================================================
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 6443/tcp comment "k3s API server"
ufw allow from 10.0.0.0/8 to any port 10250 comment "kubelet metrics (VPC only)"
ufw --force enable

# =============================================================================
# NIS2 Art.21: SSH hardening (disable password auth)
# =============================================================================
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
systemctl restart sshd

# =============================================================================
# NIS2 Art.25: Auditd — system audit logging
# =============================================================================
cat > /etc/audit/rules.d/nis2.rules << 'AUDIT'
# NIS2 Article 25 — Audit Rules
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k privilege_escalation
-w /var/log/auth.log -p ra -k auth_events
-a always,exit -F arch=b64 -S execve -k command_execution
-a always,exit -F arch=b64 -S open -F exit=-EACCES -k access_denied
AUDIT

systemctl enable auditd
systemctl restart auditd

# =============================================================================
# Install k3s with security hardening
# =============================================================================
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="
  server
  --cluster-name $CLUSTER_NAME
  --disable traefik
  --kube-apiserver-arg=audit-log-path=/var/log/kubernetes/audit.log
  --kube-apiserver-arg=audit-log-maxage=30
  --kube-apiserver-arg=audit-log-maxbackup=10
  --kube-apiserver-arg=audit-log-maxsize=100
  --kube-apiserver-arg=anonymous-auth=false
  --kube-apiserver-arg=tls-min-version=VersionTLS12
  --kube-controller-manager-arg=terminated-pod-gc-threshold=10
  --kubelet-arg=protect-kernel-defaults=true
  --kubelet-arg=event-qps=0
" sh -

# Wait for k3s to be ready
sleep 30
k3s kubectl get nodes

echo "[NIS2] k3s bootstrap complete for $CLUSTER_NAME ($ENVIRONMENT)"
echo "[NIS2] Security controls: UFW firewall, SSH hardened, Auditd, k3s TLS 1.2+"
