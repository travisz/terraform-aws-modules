/*
  Redis Cluster Module
*/

variable "application" {
  type        = string
  description = "The application this Redis Cluster is used by."
}

variable "engine_version" {
  type        = string
  description = "The Redis Engine Version to use"
}

variable "environment" {
  type        = string
  description = "The Environment this Redis Cluster is being deployed into (prod, dev, test, etc)."
}

variable "node_type" {
  type        = string
  description = "The instance type used for the cache nodes (default: cache.t3.small)"
  default     = "cache.t3.small"
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of Cache Nodes for the ElastiCache Cluster (default: 1)"
  default     = "1"
}

variable "security_groups" {
  description = "Security Groups to Allow Access to the Redis Cluster"
  type        = list(string)
}

variable "subnet_ids" {
  type        = list
  description = "List of subnet IDs to launch the cluster in"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to launch the cluster in"
}
