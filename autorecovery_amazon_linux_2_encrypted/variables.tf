/*
  Autorecovery Module Variables for Amazon Linux V2
*/

variable "subnet_id" {
  type        = string
  description = "Subnet to deploy instance to."
}

variable "instance_type" {
  type        = string
  description = "Valid Instance type to launch the instance as"
}

variable "name" {
  type        = string
  description = "Name of instance."
}

variable "security_groups" {
  description = "List of the security groups to associate with the instane"
  type        = list
}

variable "root_volume_size" {
  type        = string
  description = "Disk size of root volume (default: 20)"
  default     = 20
}

variable "root_volume_type" {
  type        = string
  description = "Disk type for root volume (Default: gp2)"
  default     = "gp2"
}

variable "enable_enhanced_health_reporting" {
  default     = true
  description = "Enable Detailed Monitoring (Default: true)"
}

variable "environment" {
  type        = string
  description = "Environment the EC2 instance is deployed to."
}

variable "application" {
  type        = string
  description = "Application the EC2 instance is deployed to."
}

variable "key_name" {
  default     = ""
  type        = string
  description = "Name of SSH Key to add to the EC2 instance (default: blank)"
}

variable "additional_policy_arns" {
  type        = list
  default     = []
  description = "List of additional policies to attach to instance"
}
