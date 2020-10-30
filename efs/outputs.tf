output "endpoint" {
  value = aws_efs_file_system.efs.dns_name
}

output "volume_arn" {
  value = aws_efs_file_system.efs.arn
}

output "volume_id" {
  value = aws_efs_file_system.efs.id
}

output "mount_target_ids" {
  value = aws_efs_mount_target.efs.*.id
}

output "mount_target_interface_ids" {
  value = aws_efs_mount_target.efs.*.network_interface_id
}
