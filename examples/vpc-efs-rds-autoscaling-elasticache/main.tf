provider "aws" {
  region = var.region
}

# Define Local Variables
locals {
  environment      = lookup(var.workspace_to_env_map, terraform.workspace, "dev")
  size             = local.environment == "dev" ? lookup(var.workspace_to_size_map, terraform.workspace, "t3.medium") : var.env_to_size_map[local.environment]
  rds_size         = local.environment == "dev" ? lookup(var.env_to_rds_map, terraform.workspace, "db.t3.medium") : var.env_to_rds_map[local.environment]
  vpc_cidr         = local.environment == "dev" ? lookup(var.env_to_vpc_cidr_map, terraform.workspace, "172.19.0.0/19") : var.env_to_vpc_cidr_map[local.environment]
  vpc_private_cidr = local.environment == "dev" ? lookup(var.env_to_private_network_map, terraform.workspace, ["172.19.16.0/24", "172.19.17.0/24"]) : var.env_to_private_network_map[local.environment]
  vpc_public_cidr  = local.environment == "dev" ? lookup(var.env_to_public_network_map, terraform.workspace, ["172.19.16.0/24", "172.19.17.0/24"]) : var.env_to_public_network_map[local.environment]
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

/* Terraform State Backend
 Make sure to execute `terraform apply` in the "remote-state" folder.
 Variables are not allowed here, make sure to set the region appropriately.

 NOTE: You will need to customize and uncomment this to use remote state.
*/
#terraform {
#  backend "s3" {
#    bucket = "my-cool-bucket"
#    key    = "state"
#    region = "us-east-2"
#  }
#}

# Default Encryption of EBS Volumes
resource "aws_ebs_encryption_by_default" "volume_encryption" {
  enabled = true
}

# Generate Key Pair for AWS Resources
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${data.aws_caller_identity.current.account_id}-${var.application}-${local.environment}-${data.aws_region.current.name}"
  public_key = tls_private_key.key.public_key_openssh
}

# Base Network
module "base_network" {
  source                   = "../../base_network"
  environment              = local.environment
  name                     = "${local.environment}-network"
  availability_zones_count = 2
  vpc_cidr_range           = local.vpc_cidr
  public_subnets           = local.vpc_public_cidr
  private_subnets          = local.vpc_private_cidr
  redundant_nat_gateways   = true
}

# EFS
module "efs" {
  source        = "../../efs"
  application   = var.application
  environment   = local.environment
  subnet_amount = "2"
  subnets       = module.base_network.private_subnets
  vpc_id        = module.base_network.vpc_id

  security_groups = [
    aws_security_group.web.id
  ]
}

# Redis Cluster
module "redis" {
  source          = "../../redis"
  environment     = local.environment
  application     = var.application
  engine_version  = "5.0.5"
  num_cache_nodes = "2"
  subnet_ids      = module.base_network.private_subnets
  vpc_id          = module.base_network.vpc_id

  security_groups = [
    aws_security_group.web.id
  ]
}

# MariaDB Cluster
module "mariadb" {
  source                 = "../../rds"
  environment            = local.environment
  application            = var.application
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  instance_type          = local.rds_size
  subnets                = module.base_network.private_subnets
  rds_engine             = "mariadb"
  rds_engine_version     = "10.2"
  parameter_group_family = "mariadb10.2"
  username               = "dbadmin"

  security_groups = [
    aws_security_group.web.id
  ]
}

# ALB Security Group
resource "aws_security_group" "alb_security_group" {
  name        = "${local.environment}-${var.application}-ALB-Sg"
  description = "Security Group for ${local.environment} ${var.application} Load Balancer"
  vpc_id      = module.base_network.vpc_id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Environment = local.environment
    Name        = "${local.environment}-${var.application}-ALB-Sg"
  }
}

# ALB
resource "aws_lb" "web" {
  name               = "${local.environment}-${var.application}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb_security_group.id
  ]

  subnets = module.base_network.public_subnets

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Application = var.application
    Environment = local.environment
    Name        = "${local.environment}-${var.application}-ALB"
  }
}

# ALB - Target Group
resource "aws_lb_target_group" "web" {
  name_prefix = "web"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = module.base_network.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Application = var.application
    Environment = local.environment
    Name        = "${local.environment}-${var.application}-80-TG"
  }
}

# ALB - Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# EC2 Security Group
resource "aws_security_group" "web" {
  name        = "${local.environment}-Web-Sg"
  description = "Security Group for ${local.environment} Web Server Access"
  vpc_id      = module.base_network.vpc_id

  ingress {
    to_port         = "80"
    from_port       = "80"
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    to_port     = 0
    from_port   = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Applicaiton = var.application
    Environment = local.environment
    Name        = "${local.environment}-${var.application}-Web-Sg"
  }
}

# EC2 Auto-Scaling Group
module "application" {
  source = "../../autoscale_amazon_linux_2_encrypted"

  name                             = "${local.environment}-${var.application}-web-app"
  key_name                         = aws_key_pair.generated_key.id
  tier                             = "web-app"
  environment                      = local.environment
  application                      = var.application
  subnet_ids                       = module.base_network.private_subnets
  enable_enhanced_health_reporting = true
  min_size                         = var.app_asg_min_size
  max_size                         = var.app_asg_max_size
  instance_type                    = local.size
  efs_mount_target_ids             = module.efs.mount_target_ids
  efs_fs_id                        = module.efs.volume_id

  root_volume_size = 80

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  security_groups = [
    aws_security_group.web.id
  ]
}

# Private Zone / Internal DNS Records
module "private_zone" {
  source      = "./private-zone"
  application = var.application
  environment = lower(local.environment)
  vpc_id      = module.base_network.vpc_id
}

resource "aws_route53_record" "alb" {
  zone_id = module.private_zone.private_hosted_zone_id
  name    = "alb.${local.environment}.local"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.web.dns_name]
}

resource "aws_route53_record" "efs" {
  zone_id = module.private_zone.private_hosted_zone_id
  name    = "efs.${local.environment}.local"
  type    = "CNAME"
  ttl     = "300"
  records = [module.efs.endpoint]
}

resource "aws_route53_record" "mysql" {
  zone_id = module.private_zone.private_hosted_zone_id
  name    = "mysql.${local.environment}.local"
  type    = "CNAME"
  ttl     = "300"
  records = [module.mariadb.endpoint]
}

resource "aws_route53_record" "redis" {
  zone_id = module.private_zone.private_hosted_zone_id
  name    = "redis.${local.environment}.local"
  type    = "CNAME"
  ttl     = "300"
  records = [module.redis.endpoint]
}
