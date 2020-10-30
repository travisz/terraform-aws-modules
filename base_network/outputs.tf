/*
  Base Network Module Outputs
*/

## Outputs

output "private_subnets" {
  value = aws_subnet.private_subnet.*.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet.*.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "availability_zones" {
  value = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)
}
