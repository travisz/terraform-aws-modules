/*
  RDS Outputs
*/
output "rds_security_group_id" {
  value = aws_security_group.rds_security_group.id
}

output "username_parameter_name" {
  value = aws_ssm_parameter.rds_username.name
}

output "password_parameter_name" {
  value = aws_ssm_parameter.rds_password.name
}

output "endpoint_parameter_name" {
  value = aws_ssm_parameter.rds_endpoint.name
}

output "endpoint" {
  value = aws_db_instance.rds.address
}
