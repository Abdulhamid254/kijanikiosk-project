
#!/bin/bash
# ==============================================================================
# KIJANIKIOSK PROVISIONING SCRIPT
# ==============================================================================
# Expected dirty conditions found in pre-provisioning audit:
# - kk-api, kk-payments, kk-logs already exist with active /bin/sh shells: handled in Phase 1 by usermod lockdown
# - group 'kijanikiosk' exists with non-standard GID 1001 instead of 1002: handled in Phase 1 by dynamic group alignment
# - /opt/kijanikiosk/config has unsafe global 777 (rwxrwxrwx) permissions: fixed in Phase 2 by chown and chmod 750
# - /opt/kijanikiosk/shared/logs is missing required app-layer FACL entries: fixed in Phase 3 by targeted setfacl policies
# - ufw has extra deny 3001 rules from Thursday remediation: reset in Phase 5 by ufw force reset
# - unmanaged package hold set on curl: cleared in Phase 4 via apt-mark unhold
# ==============================================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Phase 1: Aligning Groups and Hardening Users..."

# 1. Force the group to exist first (ignores error if it's already there)
sudo groupadd -g 1002 kijanikiosk 2>/dev/null

# 2. force the GID to 1002 (safe for existing users)
sudo groupmod -g 1002 kijanikiosk


echo "==> Phase 2: Creating and Hardening Service Accounts..."

# ----------------- User 1: kk-api (UID 997) -----------------
echo "Processing and hardening user account: kk-api"
sudo useradd -u 997 -g kijanikiosk -M -s /usr/sbin/nologin kk-api 2>/dev/null
sudo usermod -u 997 -g kijanikiosk -s /usr/sbin/nologin kk-api
sudo rm -rf /home/kk-api

# ----------------- User 2: kk-payments (UID 994) -----------------
echo "Processing and hardening user account: kk-payments"
sudo useradd -u 994 -g kijanikiosk -M -s /usr/sbin/nologin kk-payments 2>/dev/null
sudo usermod -u 994 -g kijanikiosk -s /usr/sbin/nologin kk-payments
sudo rm -rf /home/kk-payments

# ----------------- User 3: kk-logs (UID 993) -----------------
echo "Processing and hardening user account: kk-logs"
sudo useradd -u 993 -g kijanikiosk -M -s /usr/sbin/nologin kk-logs 2>/dev/null
sudo usermod -u 993 -g kijanikiosk -s /usr/sbin/nologin kk-logs
sudo rm -rf /home/kk-logs


echo "==> Phase 2: Remediating Directory Tree and Config Exposure..."
sudo mkdir -p /opt/kijanikiosk/config
sudo mkdir -p /opt/kijanikiosk/shared/logs

# Fix the 777 exposure on config folder to strict root/kijanikiosk ownership and secure permissions
sudo chown -R root:kijanikiosk /opt/kijanikiosk/config
sudo chmod 750 /opt/kijanikiosk/config

echo "==> Phase 3: Applying Advanced File Access Control Lists (FACL)..."
# Grant kk-logs read/write/execute and kk-payments read/write permissions cleanly
sudo chmod  775  /opt/kijanikiosk/shared/logs
sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs
sudo chmod 750 /opt/kijanikiosk/shared/logs
sudo usermod -aG kijanikiosk kk-payments
sudo setfacl -m u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::- /opt/kijanikiosk/shared/logs
sudo setfacl -d -m u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::-



echo "==> Phase 4: Synchronizing Packages and Tracking Policies..."
# Clear unmanaged holds to ensure latest security patches compile cleanly
sudo apt-mark unhold curl || true
sudo apt-get update && sudo apt-get install -y curl acl

echo "==> Phase 5: Purging and Rebuilding Firewall Baseline..."
# Flush dirty rules (like the leftover deny 3001) and reset to pure production baseline
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw --force enable

echo "==> converged successfully!"
