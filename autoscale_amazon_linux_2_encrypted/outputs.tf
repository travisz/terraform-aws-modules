/*
  Amazon Linux V2 AutoScale Outputs
*/

output "asg_arn" {
  value = aws_autoscaling_group.asg.arn
}

output "asg_id" {
  value = aws_autoscaling_group.asg.id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
