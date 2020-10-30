/*
  Route53 Private Zone
*/

resource "aws_route53_zone" "private" {
  name = "${var.environment}.local"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment} Internal Zone File"
  }
}
