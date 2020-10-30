/*
  AWS EFS Module
*/

resource "aws_efs_file_system" "efs" {
  encrypted = true

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-EFS"
  }
}

resource "aws_efs_mount_target" "efs" {
  file_system_id  = aws_efs_file_system.efs.id
  count           = var.subnet_amount
  subnet_id       = element(var.subnets, count.index)
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "${var.environment}-${var.application}-EFS-Sg"
  description = "Allows access to EFS for ${var.environment} ${var.application}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port       = "2049"
    to_port         = "2049"
    protocol        = "tcp"
    security_groups = var.security_groups
    description     = "Inbound port 2049 access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-EFS-Sg"
  }
}
