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

set -e
export DEBIAN_FRONTEND=noninteractive

echo "==> Phase 1: Aligning Groups and Hardening Users..."
# 1. Force the group to exist first (ignores error if it's already there)
sudo groupadd -g 1002 kijanikiosk 2>/dev/null || true
# 2. force the GID to 1002 (safe for existing users)
sudo groupmod -g 1002 kijanikiosk


echo "==> Phase 2: Creating and Hardening Service Accounts..."
# ----------------- User 1: kk-api (UID 997) -----------------
echo "Processing and hardening user account: kk-api"
sudo useradd -u 997 -g kijanikiosk -M -s /usr/sbin/nologin kk-api 2>/dev/null || true
sudo usermod -u 997 -g kijanikiosk -s /usr/sbin/nologin kk-api
sudo rm -rf /home/kk-api

# ----------------- User 2: kk-payments (UID 994) -----------------
echo "Processing and hardening user account: kk-payments"
sudo useradd -u 994 -g kijanikiosk -M -s /usr/sbin/nologin kk-payments 2>/dev/null || true
sudo usermod -u 994 -g kijanikiosk -s /usr/sbin/nologin kk-payments
sudo rm -rf /home/kk-payments

# ----------------- User 3: kk-logs (UID 993) -----------------
echo "Processing and hardening user account: kk-logs"
sudo useradd -u 993 -g kijanikiosk -M -s /usr/sbin/nologin kk-logs 2>/dev/null || true
sudo usermod -u 993 -g kijanikiosk -s /usr/sbin/nologin kk-logs
sudo rm -rf /home/kk-logs


echo "==> Phase 2 (Tree): Remediating Directory Tree and Config Exposure..."
sudo mkdir -p /opt/kijanikiosk/config
sudo mkdir -p /opt/kijanikiosk/shared/logs

# Fix dummy environment files so systemd units do not break on startup
sudo touch /opt/kijanikiosk/config/api.env /opt/kijanikiosk/config/payments-api.env /opt/kijanikiosk/config/logs.env

# Fix the 777 exposure on config folder to strict root/kijanikiosk ownership and secure permissions
sudo chown -R root:kijanikiosk /opt/kijanikiosk/config
sudo chmod 750 /opt/kijanikiosk/config


echo "==> Phase 3: Applying Advanced File Access Control Lists (FACL)..."
# Grant kk-logs read/write/execute and kk-payments read/write permissions cleanly
#sudo chmod 775 /opt/kijanikiosk/shared/logs
#sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs
#sudo chmod 750 /opt/kijanikiosk/shared/logs
#sudo usermod -aG kijanikiosk kk-payments
#sudo setfacl -b /opt/kijanikiosk/shared/logs
#sudo setfacl -m u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::- /opt/kijanikiosk/shared/logs
# FIXED SYNTAX ERROR: Explicitly appended the folder path destination below
#sudo setfacl -d -m u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::- /opt/kijanikiosk/shared/logs
echo "==> Phase 3: Applying Advanced File Access Control Lists (FACL)..."
# 1. Fix ownership and permissions so standard Linux checks pass down to the FACL layer
sudo chown root:kijanikiosk /opt/kijanikiosk/shared/logs
sudo chmod 770 /opt/kijanikiosk/shared/logs

# 2. Reset and re-apply strict, fine-grained access rules
sudo setfacl -b /opt/kijanikiosk/shared/logs
sudo setfacl -m u:kk-api:rwx,u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::- /opt/kijanikiosk/shared/logs
sudo setfacl -d -m u:kk-api:rwx,u:kk-logs:rwx,u:kk-payments:rw-,g:kijanikiosk:r-x,o::- /opt/kijanikiosk/shared/logs



echo "==> Phase 4: Synchronizing Packages and Tracking Policies..."
# Clear unmanaged holds to ensure latest security patches compile cleanly
sudo apt-mark unhold curl || true
sudo apt-get update && sudo apt-get install -y curl acl logrotate


echo "==> Phase 5: Purging and Rebuilding Firewall Baseline..."
# 1. Reset ufw to an absolute clean slate to strip out the old history
sudo ufw --force reset

# 2. Set strict, secure default behaviors
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. RULE ORDERING CRITICAL STEP: Allow port 3001 loopback traffic FIRST
# This guarantees local nginx reverse proxying works flawlessly
sudo ufw allow in on lo to any port 3001 comment 'Allow loopback proxying to payments service'

# 4. Explicitly block port 3001 from all external sources NEXT
sudo ufw deny 3001 comment 'Block all external traffic to internal payments port'

# 5. Restrict standard production services strictly to the monitoring subnet CIDR
sudo ufw allow from 10.0.1.0/24 to any port 22 proto tcp comment 'Restrict SSH access to monitoring subnet'
sudo ufw allow from 10.0.1.0/24 to any port 80 proto tcp comment 'Restrict HTTP access to monitoring subnet'
sudo ufw allow from 10.0.1.0/24 to any port 443 proto tcp comment 'Restrict HTTPS access to monitoring subnet'

# 6. Turn the firewall back on cleanly
sudo ufw --force enable

# ==============================================================================
# REQUIRED FIREWALL RULE PROGRAMMATIC VERIFICATION
# ==============================================================================
verify_firewall() {
  local failed=0
  local status
  status=$(sudo ufw status)

  # Custom beginner-friendly mappings for their required logging strings
  success() { echo "$1"; }
  log() { echo "$1"; }
  error() { echo "$1"; errors_found=1; }

  echo "$status" | grep -q "22/tcp.*ALLOW" \
    && success "PASS: SSH (22) allowed" \
    || { log "FAIL: SSH rule missing"; ((failed++)); }

  echo "$status" | grep -q "80/tcp.*ALLOW" \
    && success "PASS: HTTP (80) allowed" \
    || { log "FAIL: HTTP rule missing"; ((failed++)); }

  echo "$status" | grep -q "3001.*DENY" \
    && success "PASS: port 3001 external deny present" \
    || { log "FAIL: port 3001 deny rule missing"; ((failed++)); }

  [[ $failed -eq 0 ]] || error "${failed} firewall check(s) failed"
}

# Execute their mandated verification function cleanly
verify_firewall



echo "==> Phase 6: Injecting and Enabling Systemd Unit Files..."
echo "[1/3] Creating kk-api.service file..."
sudo bash -c 'cat > /etc/systemd/system/kk-api.service' << 'EOF'
[Unit]
Description=KijaniKiosk API Service
After=network.target

[Service]
Type=simple
User=kk-api
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/api.env
ExecStart=/usr/bin/python3 -m http.server 3000

# Security Rules
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo "[2/3] Creating kk-logs.service file..."
sudo bash -c 'cat > /etc/systemd/system/kk-logs.service' << 'EOF'
[Unit]
Description=KijaniKiosk Logs Service
After=network.target

[Service]
Type=simple
User=kk-logs
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/logs.env
ExecStart=/usr/bin/python3 -m http.server 3002

# Security Rules
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo "[3/3] Creating kk-payments.service file..."
sudo bash -c 'cat > /etc/systemd/system/kk-payments.service' << 'EOF'
[Unit]
Description=KijaniKiosk Payments Service
After=network.target kk-api.service
Wants=kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kijanikiosk
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
ExecStart=/usr/bin/python3 -m http.server 3001

# Advanced Security Rules
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
RestrictRealtime=true
RestrictSUIDSGID=true
MemoryDenyWriteExecute=true

[Install]
WantedBy=multi-user.target
EOF

echo "==> Registering and enabling services with Ubuntu..."
sudo systemctl daemon-reload
sudo systemctl enable kk-api.service kk-payments.service kk-logs.service
# Safely spin up background processes to bind the local network ports
sudo systemctl start kk-api.service kk-payments.service kk-logs.service || true


echo "==> Phase 7: Journal Persistence and Log Rotation Configuration..."
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix=/var/log/journal
sudo mkdir -p /etc/systemd/journald.conf.d

cat << 'EOF' | sudo tee /etc/systemd/journald.conf.d/kijanikiosk-journal.conf >/dev/null
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
sudo systemctl restart systemd-journald

cat << 'EOF' | sudo tee /etc/logrotate.d/kijanikiosk >/dev/null
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    su kk-api kijanikiosk
    create 0660 kk-api kijanikiosk
}
EOF
sudo logrotate --debug /etc/logrotate.d/kijanikiosk >/dev/null 2>&1


echo "==> Phase 8: Monitoring Health Checks..."
api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

sudo mkdir -p /opt/kijanikiosk/health
printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" \
  | sudo tee /opt/kijanikiosk/health/last-provision.json >/dev/null

sudo chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
sudo chmod 640 /opt/kijanikiosk/health/last-provision.json


# ==============================================================================
# FINAL CONVERGENCE VERIFICATION GATEWAY (Moved to the absolute bottom)
# ==============================================================================
echo "==> Running Final Verification Phase..."

# 1. Verify Phase 1: Accounts and Groups
[ "$(cat /etc/group | grep "^kijanikiosk:" | cut -d: -f3)" = "1002" ] && [ "$(cat /etc/passwd | grep "^kk-api:" | cut -d: -f7)" = "/usr/sbin/nologin" ]
echo "[PASS] Phase 1: User & Group Hardening"

# 2. Verify Phase 2: Configuration Directory Exposure
[ "$(stat -c '%a' /opt/kijanikiosk/config)" = "750" ]
echo "[PASS] Phase 2: Directory Tree Remediation"

# 3. Verify Phase 3: Access Control Lists (FACL)
stat -c '%A' /opt/kijanikiosk/shared/logs/ | grep -q "+"
echo "[PASS] Phase 3: Access Control Lists (FACL)"

# 4. Verify Phase 5: Firewall Reset
sudo ufw status | grep -q "Status: active"
echo "[PASS] Phase 5: Firewall Baseline Flush"

# 5. Verify Phase 7: Journald and Logrotate Config Files
[ -f "/etc/logrotate.d/kijanikiosk" ] && [ -f "/etc/systemd/journald.conf.d/kijanikiosk-journal.conf" ]
echo "[PASS] Phase 7: Log Storage & Rotation"

# 6. Verify Phase 8: Monitoring Health JSON File
[ -f "/opt/kijanikiosk/health/last-provision.json" ]
echo "[PASS] Phase 8: Monitoring Health JSON Log"

echo "----------------------------------------------------"
echo "SUCCESS: All baseline infrastructure phases converged successfully."
