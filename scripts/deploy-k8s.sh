#!/usr/bin/env bash
# Copies k8s/ to the control-plane node, creates the runtime Secret
# (DATABASE_URL + REDIS_URL) and applies all manifests.
#
# REDIS_MODE=elasticache  (default) -> uses the ElastiCache endpoint created by Terraform
# REDIS_MODE=incluster              -> uses the Redis StatefulSet inside the cluster
set -euo pipefail
cd "$(dirname "$0")/../terraform"

KEY="${SSH_KEY:-$HOME/.ssh/barq-lab}"
REDIS_MODE="${REDIS_MODE:-elasticache}"

IP="$(terraform output -raw control_plane_public_ip)"
RDS="$(terraform output -raw rds_endpoint | sed 's/:5432$//')"
USER_DB="$(terraform output -raw db_username 2>/dev/null || echo barq_admin)"
DB_NAME="$(terraform output -raw db_name 2>/dev/null || echo barq)"
PASS="$(awk -F'"' '/^db_password/ {print $2}' terraform.tfvars)"

if [ "$REDIS_MODE" = "elasticache" ]; then
  REDIS_HOST="$(terraform output -raw redis_endpoint)"
  REDIS_TOKEN="$(awk -F'"' '/^redis_auth_token/ {print $2}' terraform.tfvars)"
  REDIS_URL="rediss://:${REDIS_TOKEN}@${REDIS_HOST}:6379/0"
  APPLY_REDIS="false"
else
  REDIS_URL="redis://redis:6379/0"
  APPLY_REDIS="true"
fi

SSH_OPTS=(-i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

scp -r "${SSH_OPTS[@]}" ../k8s ubuntu@"$IP":~/

ssh "${SSH_OPTS[@]}" ubuntu@"$IP" bash -s <<REMOTE
set -e
cd ~/k8s
kubectl apply -f namespace.yaml
kubectl apply -f storage/local-path-provisioner.yaml
kubectl apply -f config/app-configmap.yaml
kubectl -n barq-assessment create secret generic barq-runtime-secret \\
  --from-literal=DATABASE_URL="postgresql://${USER_DB}:${PASS}@${RDS}:5432/${DB_NAME}?sslmode=require" \\
  --from-literal=REDIS_URL="${REDIS_URL}" \\
  --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f db/init-job.yaml
kubectl -n barq-assessment wait --for=condition=complete job/barq-db-init --timeout=180s
if [ "${APPLY_REDIS}" = "true" ]; then kubectl apply -f redis/; fi
kubectl apply -f app/
kubectl apply -f nginx/
kubectl -n barq-assessment rollout status deployment/barq-app --timeout=180s
kubectl -n barq-assessment get pods -o wide
REMOTE
