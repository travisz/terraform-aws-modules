/*
  RDS Module
*/

data "aws_subnet" "selected" {
  id = element(var.subnets, 0)
}

data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_password" "rds_pass" {
  length           = 16
  special          = true
  override_special = "#$(*&"
}

locals {
  password      = var.password != "" ? var.password : random_password.rds_pass.result
  instance_name = "${lower(var.environment)}-${lower(var.application)}-rds"
  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-RDS"
    Tier        = "RDS"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "${local.instance_name}-sbn-grp"
  subnet_ids = var.subnets

  tags = local.tags
}

resource "aws_security_group" "rds_security_group" {
  name        = "${var.environment}-${var.application}-RDS-Sg"
  description = "${var.environment} ${var.application} RDS Security Group."
  vpc_id      = data.aws_subnet.selected.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    security_groups = var.security_groups
    protocol        = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-RDS-Sg"
    Tier        = "RDS"
  }
}

resource "aws_db_parameter_group" "custom" {
  name   = "${lower(var.environment)}-${lower(var.application)}-parameter-group"
  family = var.parameter_group_family
}

resource "aws_db_instance" "rds" {
  identifier              = local.instance_name
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  username                = var.username
  password                = local.password
  storage_type            = var.storage_type
  instance_class          = var.instance_type
  skip_final_snapshot     = true
  multi_az                = var.environment == "Prod" ? true : false
  storage_encrypted       = true
  backup_retention_period = 35
  parameter_group_name    = aws_db_parameter_group.custom.name

  db_subnet_group_name   = aws_db_subnet_group.rds.id
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  tags = local.tags
}

# SSM Parameters
resource "aws_ssm_parameter" "rds_username" {
  name        = "/${var.environment}/rds/username"
  description = "Username to access RDS database ${local.instance_name}"
  type        = "SecureString"
  value       = var.username

  tags = local.tags
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "/${var.environment}/rds/password"
  description = "Password to access RDS database ${local.instance_name}"
  type        = "SecureString"
  value       = local.password

  tags = local.tags
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/${var.environment}/rds/endpoint"
  description = "Endpoint to access RDS database ${local.instance_name}"
  type        = "SecureString"
  value       = aws_db_instance.rds.endpoint

  tags = local.tags
}
