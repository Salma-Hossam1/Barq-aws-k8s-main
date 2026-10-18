# Kubernetes Secret

The Secret holds the RDS connection string (it contains the DB password), so it is
**never committed**. `barq-runtime-secret.example.yaml` only shows the shape with fake values.

Create the real Secret on the control-plane node (where kubectl is configured):

```bash
read -rsp "RDS password: " DB_PASSWORD; echo
RDS_ENDPOINT="<paste the rds_endpoint terraform output>"

kubectl -n barq-assessment create secret generic barq-runtime-secret \
  --from-literal=DATABASE_URL="postgresql://barq_admin:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/barq?sslmode=require"

unset DB_PASSWORD
```

Use the same user, password and database name as in Terraform (`db_username`, `db_password`, `db_name`).
Keep the password to letters and digits so it is URL-safe.
