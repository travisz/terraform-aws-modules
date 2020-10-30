/*
  RDS Module Variables
*/

variable "subnets" {
  type        = list
  description = "List of subnets to deploy the cluster to."
}

variable "environment" {
  type        = string
  description = "Environment the RDS Cluster belongs to."
}

variable "application" {
  type        = string
  description = "Application the RDS Cluster belongs to."
}

variable "allocated_storage" {
  default     = 50
  description = "Starting allocated storage."
}

variable "max_allocated_storage" {
  default     = 100
  description = "The maximum size RDS storage can be automatically scaled to."
}

variable "storage_type" {
  default     = "gp2"
  description = "Type of storage to use (gp2, io1, standard), defaults to gp2"
}

variable "rds_engine" {
  type        = string
  default     = ""
  description = "Engine of RDS to deploy."
}

variable "rds_engine_version" {
  type        = string
  default     = ""
  description = "Version of RDS to deploy."
}

variable "instance_type" {
  default     = "db.t3.large"
  description = "Instance type to provision RDS on."
}

variable "username" {
  type        = string
  default     = "dbadmin"
  description = "Username to connect to RDS instance."
}

variable "password" {
  type        = string
  default     = ""
  description = "Password to connect to RDS instance. If left blank Terraform will generate a password and store it in SSM."
}

variable "security_groups" {
  description = "List of Security Groups to add to the RDS Instance"
  type        = list(string)
}

variable "parameter_group_family" {
  description = "Parameter Group Family for the RDS instance type (ex: mariadb10.2)"
  type        = string
}
