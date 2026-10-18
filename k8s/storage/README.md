# Redis storage

Redis uses a `volumeClaimTemplate` in its StatefulSet (`redis/statefulset.yaml`):
a 128Mi PVC with `storageClassName: local-path`, mounted at `/data`, with AOF persistence on.
The `local-path` StorageClass is provided by `local-path-provisioner.yaml`.

**Where the data really lives:** a directory on the disk of the worker node that first ran the
Redis pod (`/opt/local-path-provisioner/...`).

**Limitation (required in the submission):**
- Redis pod deleted/recreated -> data survives (same PVC, same node).
- Worker node replaced or terminated -> data is LOST. Local-path storage is not replicated
  and is tied to one node. A PVC protects against pod failure, not node failure.
- Nothing here protects against EC2 disk failure either; there are no backups.

Production alternatives: EBS CSI driver (survives node replacement within an AZ) or
Amazon ElastiCache (the optional bonus).
