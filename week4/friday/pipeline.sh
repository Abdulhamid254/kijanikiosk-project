#!/bin/bash
# ==============================================================================
# KijaniKiosk End-to-End Infrastructure Deployment Pipeline (Requirement 3)
# Usage: ./pipeline.sh [multipass|cloud]
# ==============================================================================

# Rule 1: Instruct shell to fail immediately if any individual step exits non-zero
set -e

PATH_MODE=${1:-multipass}
INVENTORY_FILE="inventory.ini"

echo "=== [Phase 1/4] Running Infrastructure Provisioning Engine (Terraform) ==="
# Initialize plugins and run apply with an auto-approve flag to run hands-free
terraform init
terraform apply -auto-approve

echo "=== [Phase 2/4] Harvesting Machine Topography & Mapping Context (${PATH_MODE} mode) ==="
# Start with a clean slate by writing the inventory group header to inventory.ini
echo "[kijanikiosk_nodes]" > $INVENTORY_FILE

if [ "$PATH_MODE" = "multipass" ]; then
  # Dynamic Multipass Extraction Path (Challenge A Compliance)
  for ROLE in api payments logs; do
    echo "Fetching virtual dynamic IP parameter for node: kijanikiosk-${ROLE}"
    NODE_IP=$(multipass info "kijanikiosk-${ROLE}" 2>/dev/null | grep IPv4 | awk '{print $2}') || true
    
    if [ -z "$NODE_IP" ]; then
      echo "ERROR: Failed to resolve active network interface for target role: ${ROLE}" >&2
      exit 1
    fi
    # Write the dynamic parameters directly into your inventory file
    echo "${ROLE} ansible_host=${NODE_IP} server_role=${ROLE}" >> $INVENTORY_FILE
  done
else
  # Alternate Cloud Path Option (Programmatically extracting raw blocks from Terraform outputs)
  echo "Extracting structured inventory string output directly from state mappings..."
  terraform output -raw ansible_inventory_content >> $INVENTORY_FILE
fi

echo "=== [Phase 3/4] Validating Written Inventory Structure ==="
cat $INVENTORY_FILE

echo "=== [Phase 4/4] Activating Configuration Hardening Engine (Ansible) ==="
# Execute the syntax check pre-flight gate dynamically
ansible-playbook -i $INVENTORY_FILE playbook.yaml --syntax-check

# Run the full hardening playbook using the newly created inventory file
ansible-playbook -i $INVENTORY_FILE playbook.yaml

echo "=== [Pipeline Success] Convergence Confirmed. Environment Reprodubly Operational ==="
