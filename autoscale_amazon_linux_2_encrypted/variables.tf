/*
  Autoscaling Variables
*/

### Application Settings ###
variable "name" {
  description = "Name variable passed in from the root main.tf"
  type        = string
}

variable "environment" {
  description = "Name of the environment"
  type        = string
}

variable "application" {
  description = "Name of the application"
  type        = string
}

variable "tier" {
  description = "Tier of application (ex: web, app, cms, etc)"
  type        = string
}

variable "subnet_ids" {
  description = "List of the subnet IDs to use with the auto-scaling group"
  type        = list
}

### EC2 Settings ###
variable "instance_type" {
  default = "t3.small"
  description = "Size of the instance to use in the ASG (default: t3.small)"
  type    = string
}

variable "additional_policy_arns" {
  default     = []
  description = "List of additional policies to attach to instance"
  type        = list
}

variable "root_volume_type" {
  default     = "gp2"
  description = "Type of disk for the root volume (default: gp2)"
  type        = string
}

variable "root_volume_size" {
  default     = 30
  description = "Root volume size (default: 30)"
  type        = number
}

variable "security_groups" {
  description = "List of Security Groups to associate with the Launch Template"
  type        = list
}

variable "enable_enhanced_health_reporting" {
  default     = true
  description = "Enable Enhanced Monitoring (default: true)"
  type        = string
}

variable "key_name" {
  default     = ""
  description = "The name of the EC2 SSH Key to assign to the Autoscaling Group"
  type        = string
}

variable "min_size" {
  default     = 2
  description = "Minimum Size of the Auto-Scaling Group (default: 2)"
  type        = number
}

variable "max_size" {
  default     = 4
  description = "Maximum Size of the Auto-Scaling Group (default: 4)"
  type        = number
}

variable "cpu_low_threshold" {
  default     = 20
  description = "Minimum level of autoscale metric to remove an instance (default: 20)"
  type        = number
}

variable "scale_down_adjustment" {
  default     = -1
  description = "How many Amazon EC2 instances to remove when performing a scaling activity. (defualt: -1)"
  type        = number
}

variable "cpu_high_threshold" {
  default     = 80
  description = "Maximum level of autoscale metric to add an instance (default: 80)"
  type        = number
}

variable "scale_up_adjustment" {
  default     = 1
  description = "How many Amazon EC2 instances to add when performing a scaling activity (default: 1)"
  type        = number
}

variable "scaling_cooldown" {
  default     = 60
  description = "Time in seconds before any further trigger-related scaling can occur. (default: 60)"
  type        = number
}

variable "health_check_grace_period" {
  default     = 300
  description = "Number of seconds grace during which no autoscaling actions will be take. (default: 300)"
  type        = number
}

variable "target_group_arns" {
  default     = []
  description = "List of target groups to associate Autoscale Group with"
  type        = list
}

variable "efs_mount_target_ids" {
  description = "List of the mount target IDs for the EFS volume"
  type        = list
}

variable "efs_fs_id" {
  description = "ID of the EFS Volume"
  type        = string
}
