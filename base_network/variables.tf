/*
  Base Network Module Variables
*/

## Variables

# Descriptive name of the Environment to add to tags (should make sense to humans)
variable "environment" {
  description = "The Environment this VPC is being deployed into (prod, dev, test, etc)"
  type        = string
}

# Name to give to the VPC and associated resources
variable "name" {
  description = "The name of the VPC"
  type        = string
}

# Number of AZs to create
variable "availability_zones_count" {
  default     = "2"
  description = "Number of Availability Zones to use"
  type        = string
}

variable "redundant_nat_gateways" {
  default     = true
  description = "Whether NAT Gateways are redundant (deployed one per availability zone)"
  type        = string
}

# Instance Tenancy (can be dedicated or default)
variable "instance_tenancy" {
  default     = "default"
  description = "VPC Instance Tenancy (single tenant - dedicated, multi-tenancy - default)"
  type        = string
}

# The CIDR Range for the entire VPC
variable "vpc_cidr_range" {
  default     = "172.18.0.0/16"
  description = "The IP Address space used for the VPC in CIDR notation."
  type        = string
}

# The CIDR Ranges for the Public Subnets
variable "public_subnets" {
  default     = ["172.18.0.0/22", "172.18.4.0/22", "172.18.8.0/22"]
  description = "IP Address Ranges in CIDR Notation for Public Subnets in AZ1-3."
  type        = list
}

# The CIDR Ranges for the Private Subnets
variable "private_subnets" {
  default     = ["172.18.32.0/21", "172.18.40.0/21", "172.18.48.0/21"]
  description = "IP Address Ranges in CIDR Notation for Private Subnets in AZ 1-3."
  type        = list
}

locals {
  nat_gateway_count = var.redundant_nat_gateways ? var.availability_zones_count : 1
}
