/*
  Base Network Module
*/

## Get available azs
data "aws_availability_zones" "available" {}

## Resources

### VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_range
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    ConnectriaManaged = "True"
    Environment       = var.environment
    Name              = format("%s-vpc", var.name)
  }
}

### Internet Gateway
resource "aws_internet_gateway" "internet" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Environment = var.environment
    Name        = "${var.name}-IGW"
  }
}

### Private Subnets
# Loop over this as many times as necessary to create the correct number of Private Subnets
resource "aws_subnet" "private_subnet" {
  count             = var.availability_zones_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Environment = var.environment
    Name        = format("%s-private-subnet-az%d", var.name, count.index + 1)
    Network     = "private"
  }
}

### Public Subnets
# Loop over this as many times as necessary to create the correct number of Public Subnets
resource "aws_subnet" "public_subnet" {
  count                   = var.availability_zones_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Environment = var.environment
    Name        = format("%s-public-subnet-az%d", var.name, count.index + 1)
    Network     = "public"
  }
}

### Elastic IPs
# Need one per AZ for the NAT Gateways
resource "aws_eip" "nat_gw_eip" {
  count = local.nat_gateway_count
  vpc   = true

  tags = {
    Environment = var.environment
    Tier        = "NAT"
  }
}

### NAT Gateways
# Loops as necessary to create one per AZ in the Public Subnets, and associate the provisioned Elastic IP
resource "aws_nat_gateway" "nat" {
  allocation_id = element(aws_eip.nat_gw_eip.*.id, count.index)
  count         = local.nat_gateway_count
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
}

### Private Subnet Route Tables
# Routes traffic destined for `0.0.0.0/0` to the NAT Gateway in the same AZ
resource "aws_route_table" "route_table_private" {
  count  = var.availability_zones_count
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.redundant_nat_gateways ? element(aws_nat_gateway.nat.*.id, count.index) : element(aws_nat_gateway.nat.*.id, 0)
  }

  tags = {
    Environment = var.environment
    Name        = format("%s-PrivateRT-AZ%d", var.name, count.index + 1)
  }
}

### Private Subnet Route Table Associations
resource "aws_route_table_association" "private_subnet_assocation" {
  count          = var.availability_zones_count
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.route_table_private.*.id, count.index)
}

### Public Route Tables
# Routes traffic destined for `0.0.0.0/0` to the Internet Gateway for the VPC
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet.id
  }

  tags = {
    Environment = var.environment
    Name        = format("%s-PublicRT", var.name)
  }
}

### Public Route Table Associations
resource "aws_route_table_association" "public_subnet_assocation" {
  count          = var.availability_zones_count
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.route_table_public.id
}
