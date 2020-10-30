/*
  Redis Cluster Module
*/

locals {
  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-Redis"
    Tier        = "Redis"
  }
}

resource "aws_elasticache_subnet_group" "redis_cluster_subnets" {
  name       = "${var.environment}-redis-cluster-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "elasticache_security_group" {
  name        = "${var.environment}-${var.application}-Redis-Sg"
  description = "Security Group for access to the ${var.environment} ${var.application} Cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = "6379"
    to_port         = "6379"
    protocol        = "tcp"
    security_groups = var.security_groups
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-Redis-Sg"
    Tier        = "Redis"
  }
}

resource "aws_elasticache_replication_group" "redis_cluster" {
  automatic_failover_enabled    = var.environment == "Prod" ? true : false
  replication_group_id          = "${lower(var.environment)}-${lower(var.application)}-redis-cluster"
  replication_group_description = "Redis cluster for ${var.environment}"
  node_type                     = var.node_type
  snapshot_window               = "00:00-05:00"
  snapshot_retention_limit      = 5
  subnet_group_name             = aws_elasticache_subnet_group.redis_cluster_subnets.name
  number_cache_clusters         = var.environment == "Prod" ? var.num_cache_nodes : 1
  engine                        = "redis"
  engine_version                = var.engine_version
  security_group_ids            = [aws_security_group.elasticache_security_group.id]
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
}

resource "aws_ssm_parameter" "redis_endpoint" {
  name        = "/${var.environment}/redis/endpoints"
  description = "Redis endpoints for ${var.environment}"
  type        = "String"
  value       = aws_elasticache_replication_group.redis_cluster.primary_endpoint_address

  tags = local.tags
}
