/*
  EFS Module Variables
*/

variable "application" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type    = list
}

variable "subnet_amount" {
  type = string
}

variable "environment" {
  type = string
}

variable "security_groups" {
  type = list
}
