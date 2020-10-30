# Variables
variable "app_asg_min_size" {
  default     = "2"
  description = "Minimum number of instances in the ASG"
  type        = number
}

variable "app_asg_max_size" {
  default     = "6"
  description = "Maximum number of instances in the ASG"
  type        = number
}

variable "application" {
  description = "Name of the application"
  type        = string
}

variable "rds_allocated_storage" {
  description = "Storage to allocate to the RDS Instance"
  type        = number
}

variable "rds_max_allocated_storage" {
  description = "Max Storage to allocate to the RDS Instance"
  type        = number
}

variable "region" {
  description = "AWS region to use"
  type        = string
}

# Environment Maps
variable "env_to_ssl_arn_map" {
  default = {
    Dev   = ""
    Prod  = ""
    Stage = ""
  }
  description = "Map for the ACM SSL ARN"
  type        = map
}

variable "env_to_vpc_cidr_map" {
  default = {
    Stage = "172.19.0.0/19"
    Prod  = "172.18.0.0/19"
    Dev   = "172.17.0.0/19"
  }
  description = "Map for the VPC CIDR Range"
  type        = map
}

variable "env_to_private_network_map" {
  default = {
    Stage = ["172.19.0.0/24","172.19.1.0/24"]
    Prod  = ["172.18.0.0/24","172.18.1.0/24"]
    Dev   = ["172.17.0.0/24","172.17.1.0/24"]
  }
  description = "Map of the private subnets"
  type        = map
}

variable "env_to_public_network_map" {
  default = {
    Stage = ["172.19.16.0/24","172.19.17.0/24"]
    Prod  = ["172.18.16.0/24","172.18.17.0/24"]
    Dev   = ["172.17.16.0/24","172.17.17.0/24"]
  }
  description = "Map of the public subnets"
  type        = map
}

variable "workspace_to_env_map" {
  default = {
    stage = "Stage"
    prod  = "Prod"
    dev   = "Dev"
  }
  description = "Map of the workspace to env"
  type        = map
}

variable "env_to_instance_map" {
  default = {
    Stage = "t3.small"
    Prod  = "m5.large"
    Dev   = "t3.small"
  }
  description = "Map of the instance size to env"
  type        = map
}

variable "env_to_rds_map" {
  default = {
    Stage = "db.t3.large"
    Prod  = "db.m5.large"
    Dev   = "db.t3.large"
  }
  description = "Map of the RDS instance size to env"
  type        = map
}

variable "env_to_size_map" {
  type = map
  default = {
    Stage = "t3.small"
    Prod  = "m5.large"
    Dev   = "t3.small"
  }
}

variable "workspace_to_size_map" {
  default = {
    Stage = "medium"
  }
  description = "Map of the workspace to size"
  type        = map
}
