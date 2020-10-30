/*
  Amazon Linux V2 AutoRecovery Outputs
*/

output "instance_id" {
  value = aws_instance.instance.id
}
