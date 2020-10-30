/*
  Amazon Linux V2 Autoscaling Group
*/

locals {
  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "${var.environment}-${var.application}-${var.tier}-ASG"
    Tier        = var.tier
  }
}

data "aws_caller_identity" "current" {}

data "template_file" "userdata" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    efs_id = var.efs_fs_id
  }
}

data "aws_iam_policy_document" "instance_role_policy_document" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "ec2:DescribeTags",
      "kms:Decrypt",
      "ssm:CreateAssociation",
      "ssm:GetParameter"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:ListMultipartUploadParts",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
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

resource "aws_launch_template" "template" {
  name_prefix   = var.name
  image_id      = data.aws_ami.amazon_linux_2.image_id
  instance_type = var.instance_type
  ebs_optimized = true
  key_name      = var.key_name != "" ? var.key_name : null

  user_data = base64encode(data.template_file.userdata.rendered)

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  monitoring {
    enabled = var.enable_enhanced_health_reporting
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
      encrypted   = true
    }
  }

  vpc_security_group_ids = var.security_groups

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
}

resource "aws_autoscaling_group" "asg" {
  name_prefix = var.name
  min_size    = var.environment != "Prod" ? 1 : var.min_size
  max_size    = var.environment != "Prod" ? 1 : var.max_size

  launch_template {
    name    = aws_launch_template.template.name
    version = aws_launch_template.template.latest_version
  }

  vpc_zone_identifier = var.subnet_ids

  # Scaling
  default_cooldown          = var.scaling_cooldown
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = "EC2"
  desired_capacity          = var.environment != "Prod" ? 1 : var.min_size

  termination_policies = [
    "OldestInstance",
    "OldestLaunchTemplate"
  ]

  target_group_arns = var.target_group_arns

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Application"
    value               = var.application
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }

  depends_on = [
    var.efs_mount_target_ids
  ]
}

resource "aws_cloudwatch_metric_alarm" "scaling_up" {
  alarm_name          = "${var.environment}-${var.application}-${var.tier}-cpu-utilization-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.health_check_grace_period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_up_asg.arn
  ]
}

resource "aws_autoscaling_policy" "scale_up_asg" {
  name                   = "${var.environment}-${var.application}-${var.tier}-scale-up"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scaling_cooldown
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scaling_down" {
  alarm_name          = "${var.environment}-${var.application}-${var.tier}-cpu-utilization-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.health_check_grace_period
  statistic           = "Average"
  threshold           = var.cpu_low_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_down_asg.arn
  ]
}

resource "aws_autoscaling_policy" "scale_down_asg" {
  name                   = "${var.environment}-${var.application}-${var.tier}-scale-down"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scaling_cooldown
  autoscaling_group_name = aws_autoscaling_group.asg.name
}
