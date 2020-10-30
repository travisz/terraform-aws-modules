/*
  Redis Cluster Module
*/

output "security_group" {
  value = aws_security_group.elasticache_security_group.id
}

output "endpoint_parameter_name" {
  value = aws_ssm_parameter.redis_endpoint.name
}

output "endpoint" {
  value = aws_elasticache_replication_group.redis_cluster.primary_endpoint_address
}
