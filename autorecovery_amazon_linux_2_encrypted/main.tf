/*
  Amazon Linux V2 AutoRecovery
*/

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "instance_role_policy_document" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
      "ssm:CreateAssociation",
      "ssm:GetParameter"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "instance_role_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "code_deploy_role" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.additional_policy_arns)
  role       = aws_iam_role.instance_role.name
  policy_arn = var.additional_policy_arns[count.index]
}

resource "aws_iam_role_policy" "instance_role_policy" {
  role   = aws_iam_role.instance_role.name
  policy = data.aws_iam_policy_document.instance_role_policy_document.json
}

resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.instance_role.name
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "instance" {
  ami                  = data.aws_ami.amazon_linux_2.image_id
  instance_type        = var.instance_type
  key_name             = var.key_name != "" ? var.key_name : null
  monitoring           = var.enable_enhanced_health_reporting
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  subnet_id            = var.subnet_id

  user_data = base64encode(file("${path.module}/bootstrap.sh"))

  root_block_device {
    encrypted   = true
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  vpc_security_group_ids = var.security_groups

  volume_tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-AutoRecovery"
  }

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-AutoRecovery"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_instance_alarm_reboot" {
  alarm_name          = "${aws_instance.instance.id}-StatusCheckFailedInstanceAlarmReboot"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "0"
  unit                = "Count"
  alarm_description   = "Status checks have failed, rebooting system"

  dimensions = {
    InstanceId = aws_instance.instance.id
  }

  alarm_actions = [join(":", list("arn", "aws", "swf", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "action/actions/AWS_EC2.InstanceId.Reboot/1.0"))]
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed_system_alarm_recover" {
  alarm_name          = "${aws_instance.instance.id}-StatusCheckFailedSystemAlarmRecover"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "0"
  unit                = "Count"

  alarm_description = "Status checks have failed for system, recovering instance"

  dimensions = {
    InstanceId = aws_instance.instance.id
  }

  alarm_actions = [join(":", list("arn", "aws", "automate", data.aws_region.current.name, "ec2", "recover"))]
}
