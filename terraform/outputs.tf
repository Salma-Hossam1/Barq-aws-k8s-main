output "control_plane_public_ip" {
  description = "Public IP of the control-plane node (SSH / NodePort)"
  value       = aws_instance.node["control-plane"].public_ip
}

output "control_plane_private_ip" {
  description = "Private IP of the control-plane node (used by kubeadm)"
  value       = aws_instance.node["control-plane"].private_ip
}

output "worker_public_ip" {
  description = "Public IP of the worker node"
  value       = aws_instance.node["worker"].public_ip
}

output "worker_private_ip" {
  description = "Private IP of the worker node"
  value       = aws_instance.node["worker"].private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host only)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Database master username"
  value       = aws_db_instance.main.username
}

output "redis_endpoint" {
  description = "ElastiCache primary endpoint (host only, no credentials)"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}
