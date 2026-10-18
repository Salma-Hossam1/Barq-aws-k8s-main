# Kubernetes manifests (BARQ lab)

Components: NGINX (NodePort 30080, the only entry point) -> `app` Service -> 2 Flask pods
-> `redis` Service (Redis StatefulSet + PVC) and Amazon RDS PostgreSQL (outside the cluster).

## Before you deploy
1. Build and push an **arm64** image (nodes are Graviton `t4g`) to a **public** Docker Hub repo:
   `docker buildx build --platform linux/arm64 -t YOUR_DOCKERHUB_USER/barq-app:1.0.0 --push .`
2. Put that image name in `app/deployment.yaml`.
3. Copy this folder to the control-plane node (the API server is not exposed to the internet):
   `scp -r -i ~/.ssh/barq-lab k8s ubuntu@<control_plane_public_ip>:~/`

## Deploy order (run on the control-plane node, inside the k8s/ folder)
```bash
kubectl apply -f namespace.yaml
kubectl apply -f storage/local-path-provisioner.yaml
kubectl apply -f config/app-configmap.yaml

# Secret: follow secrets/README.md (real value is never committed)

kubectl apply -f db/init-job.yaml            # creates the records table on RDS
kubectl -n barq-assessment wait --for=condition=complete job/barq-db-init --timeout=120s

kubectl apply -f redis/
kubectl apply -f app/
kubectl apply -f nginx/
kubectl -n barq-assessment get pods -o wide
```

## Access
`http://<any node public IP>:30080/` - only your IP is allowed by the security group.
