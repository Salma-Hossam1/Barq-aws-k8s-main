data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_cidr       = "${chomp(data.http.my_ip.response_body)}/32"
  allowed_cidrs = length(var.allowed_cidrs) > 0 ? var.allowed_cidrs : [local.my_cidr]
  node_rules = {
    k8s-api       = { protocol = "tcp", from = 6443, to = 6443, desc = "Kubernetes API server" }
    kubelet       = { protocol = "tcp", from = 10250, to = 10250, desc = "Kubelet API" }
    etcd          = { protocol = "tcp", from = 2379, to = 2380, desc = "etcd (control plane)" }
    scheduler     = { protocol = "tcp", from = 10259, to = 10259, desc = "kube-scheduler" }
    controller    = { protocol = "tcp", from = 10257, to = 10257, desc = "kube-controller-manager" }
    flannel-vxlan = { protocol = "udp", from = 8472, to = 8472, desc = "Flannel CNI VXLAN" }
  }
}

resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-nodes-sg"
  description = "Kubernetes nodes (control plane and worker)"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-nodes-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each          = toset(local.allowed_cidrs)
  security_group_id = aws_security_group.nodes.id
  description       = "SSH from approved IP"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each          = toset(local.allowed_cidrs)
  security_group_id = aws_security_group.nodes.id
  description       = "NGINX NodePort from approved IP"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 30080
  to_port           = 30080
}

resource "aws_vpc_security_group_ingress_rule" "nodes_internal" {
  for_each                     = local.node_rules
  security_group_id            = aws_security_group.nodes.id
  description                  = each.value.desc
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = each.value.protocol
  from_port                    = each.value.from
  to_port                      = each.value.to
}

resource "aws_vpc_security_group_egress_rule" "nodes_all" {
  security_group_id = aws_security_group.nodes.id
  description       = "Outbound for package downloads and image pulls"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "PostgreSQL RDS"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project_name}-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_nodes" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from application node security group only"
  referenced_security_group_id = aws_security_group.nodes.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}
