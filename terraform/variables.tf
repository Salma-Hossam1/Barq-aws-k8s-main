variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used in resource names and tags"
  type        = string
  default     = "barq"
}

variable "vpc_cidr" {
  description = "IP range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IP range of the public subnet (EC2 nodes)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "IP ranges of the two private DB subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "allowed_cidrs" {
  description = "Optional approved IPv4 CIDRs for SSH and the app. Leave empty to use your current public IP automatically."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.allowed_cidrs : can(cidrnetmask(c)) && c != "0.0.0.0/0"])
    error_message = "Each entry must be a valid IPv4 CIDR (for example 1.2.3.4/32). 0.0.0.0/0 is not allowed."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key uploaded to AWS (the private key never leaves your machine)"
  type        = string
  default     = "~/.ssh/barq-lab.pub"
}

variable "instance_type" {
  description = "EC2 instance type (arm64 Graviton to match images built on Apple Silicon)"
  type        = string
  default     = "t4g.small"
}

variable "root_volume_gb" {
  description = "Root disk size in GB for each node"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "barq"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "barq_admin"
}

variable "db_password" {
  description = "Master password for RDS (set in terraform.tfvars, never commit)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && !can(regex("[/@\"' ]", var.db_password))
    error_message = "Password must be at least 12 characters and must not contain / @ \" ' or spaces."
  }
}

variable "redis_auth_token" {
  description = "ElastiCache AUTH token (set in terraform.tfvars, never commit)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.redis_auth_token) >= 16 && length(var.redis_auth_token) <= 128 && !can(regex("[/@\"' ]", var.redis_auth_token))
    error_message = "Token must be 16-128 characters and must not contain / @ \" ' or spaces."
  }
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.micro"
}
