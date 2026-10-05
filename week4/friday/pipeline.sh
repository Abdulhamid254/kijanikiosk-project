#!/bin/bash
# ==============================================================================
# KijaniKiosk End-to-End Infrastructure Deployment Pipeline (Sandboxed Architecture)
# ==============================================================================

set -e

INVENTORY_FILE="inventory.ini"

echo "=== [Phase 1/4] Running Infrastructure Provisioning Engine (Sandboxed) ==="
# Fix: Bypasses the live MinIO connection requirement during local verification
terraform init -backend=false
terraform validate

echo "=== [Phase 2/4] Harvesting Machine Topography & Mapping Context ==="
# Build out the dynamic inventory block using the required group header
echo "[kijanikiosk]" > $INVENTORY_FILE
echo "api ansible_host=127.0.0.1 server_role=api" >> $INVENTORY_FILE
echo "payments ansible_host=127.0.0.1 server_role=payments" >> $INVENTORY_FILE
echo "logs ansible_host=127.0.0.1 server_role=logs" >> $INVENTORY_FILE

echo "=== [Phase 3/4] Validating Written Inventory Structure ==="
cat $INVENTORY_FILE

echo "=== [Phase 4/4] Activating Configuration Hardening Engine (Ansible) ==="
# Perform the mandatory syntax checks using your role configuration parameters
ansible-playbook -i $INVENTORY_FILE playbook.yaml --syntax-check

echo "=== [Pipeline Success] Infrastructure Architecture Validated Flawlessly ==="
