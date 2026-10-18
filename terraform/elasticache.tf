resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.project_name}-cache-subnets" }
}

resource "aws_security_group" "cache" {
  name        = "${var.project_name}-cache-sg"
  description = "ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-cache-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_nodes" {
  security_group_id            = aws_security_group.cache.id
  description                  = "Redis from application node security group only"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "BARQ Redis (ElastiCache, cluster mode disabled)"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.cache_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.cache.id]

  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  snapshot_retention_limit = 0
  apply_immediately        = true

  tags = { Name = "${var.project_name}-redis" }
}
