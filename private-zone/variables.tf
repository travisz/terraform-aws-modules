variable "application" {
  type        = string
  description = "Name of the application"
}

variable "environment" {
  type        = string
  description = "Name of the environment (development, production, etc)"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}
