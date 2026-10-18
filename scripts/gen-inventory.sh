#!/usr/bin/env bash
# Generates ansible/inventory/aws.ini from `terraform output`.
# Usage: ./scripts/gen-inventory.sh            (default key ~/.ssh/barq-lab)
#        SSH_KEY=~/.ssh/other ./scripts/gen-inventory.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF_DIR="$ROOT/terraform"
OUT="$ROOT/ansible/inventory/aws.ini"
KEY="${SSH_KEY:-$HOME/.ssh/barq-lab}"

tf() { terraform -chdir="$TF_DIR" output -raw "$1"; }

CP_PUB="$(tf control_plane_public_ip)"
CP_PRIV="$(tf control_plane_private_ip)"
W_PUB="$(tf worker_public_ip)"
W_PRIV="$(tf worker_private_ip)"

cat > "$OUT" <<INV
[control_plane]
control-1 ansible_host=${CP_PUB} ansible_private_ip=${CP_PRIV} ansible_user=ubuntu ansible_ssh_private_key_file=${KEY}

[workers]
worker-1 ansible_host=${W_PUB} ansible_private_ip=${W_PRIV} ansible_user=ubuntu ansible_ssh_private_key_file=${KEY}

[k8s_nodes:children]
control_plane
workers
INV

echo "Inventory written to $OUT"
