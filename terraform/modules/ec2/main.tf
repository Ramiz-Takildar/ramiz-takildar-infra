# ============================================================================
# EC2 Instance Module - Main Configuration
# ============================================================================
# This module creates EC2 instances with best practices:
# - Multiple instance support
# - Custom EBS volumes
# - Security groups
# - SSH key pairs
# - User data scripts
# - IAM instance profiles
# - Detailed monitoring
# - Tags and naming
#
# Supported Operating Systems:
# - Ubuntu (20.04, 22.04)
# - Amazon Linux 2
# - RHEL (8, 9)
# ============================================================================

# ============================================================================
# Data Sources
# ============================================================================

# Get the latest AMI based on OS selection
data "aws_ami" "selected" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================================
# EC2 Key Pair
# ============================================================================

# Create or use existing SSH key pair
resource "aws_key_pair" "this" {
  count = var.create_key_pair ? 1 : 0

  key_name   = var.key_pair_name
  public_key = var.public_key

  tags = merge(
    var.tags,
    {
      Name = var.key_pair_name
    }
  )
}

# ============================================================================
# IAM Role for EC2 Instance Profile
# ============================================================================

# IAM role for EC2 instances
resource "aws_iam_role" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name               = "${var.instance_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-role"
    }
  )
}

# Assume role policy for EC2
data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_instance_profile ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Attach managed policies to the role
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = var.create_iam_instance_profile ? toset(var.iam_managed_policy_arns) : []

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# Custom inline policy for the role
resource "aws_iam_role_policy" "custom" {
  count = var.create_iam_instance_profile && var.iam_custom_policy != "" ? 1 : 0

  name   = "${var.instance_name}-custom-policy"
  role   = aws_iam_role.this[0].id
  policy = var.iam_custom_policy
}

# IAM instance profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name = "${var.instance_name}-profile"
  role = aws_iam_role.this[0].name

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-profile"
    }
  )
}

# ============================================================================
# Security Group
# ============================================================================

# Security group for EC2 instances
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-sg"
    }
  )
}

# Ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = var.create_security_group ? { for idx, rule in var.ingress_rules : idx => rule } : {}

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks  = lookup(each.value, "ipv6_cidr_blocks", null)
  security_group_id = aws_security_group.this[0].id
  description       = lookup(each.value, "description", "Managed by Terraform")
}

# Egress rules
resource "aws_security_group_rule" "egress" {
  for_each = var.create_security_group ? { for idx, rule in var.egress_rules : idx => rule } : {}

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks  = lookup(each.value, "ipv6_cidr_blocks", null)
  security_group_id = aws_security_group.this[0].id
  description       = lookup(each.value, "description", "Managed by Terraform")
}

# ============================================================================
# EC2 Instances
# ============================================================================

# Create EC2 instances
resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.selected.id
  instance_type               = var.instance_type
  key_name                    = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_pair_name
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids
  iam_instance_profile        = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile_name
  associate_public_ip_address = var.associate_public_ip_address
  monitoring                  = var.enable_detailed_monitoring
  user_data                   = var.user_data != "" ? var.user_data : null
  user_data_base64            = var.user_data_base64 != "" ? var.user_data_base64 : null

  # Root block device configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_type == "io1" || var.root_volume_type == "io2" ? var.root_volume_iops : null
    throughput            = var.root_volume_type == "gp3" ? var.root_volume_throughput : null
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = var.root_volume_delete_on_termination

    tags = merge(
      var.tags,
      {
        Name = "${var.instance_name}-${count.index + 1}-root"
      }
    )
  }

  # Additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices

    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = lookup(ebs_block_device.value, "volume_type", "gp3")
      volume_size           = ebs_block_device.value.volume_size
      iops                  = lookup(ebs_block_device.value, "iops", null)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
      encrypted             = lookup(ebs_block_device.value, "encrypted", true)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)

      tags = merge(
        var.tags,
        {
          Name = "${var.instance_name}-${count.index + 1}-${ebs_block_device.value.device_name}"
        }
      )
    }
  }

  # Metadata options (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = var.enable_instance_metadata_tags ? "enabled" : "disabled"
  }

  # Credit specification for T2/T3 instances
  dynamic "credit_specification" {
    for_each = can(regex("^t[2-3]", var.instance_type)) ? [1] : []

    content {
      cpu_credits = var.cpu_credits
    }
  }

  # Capacity reservation
  dynamic "capacity_reservation_specification" {
    for_each = var.capacity_reservation_id != "" ? [1] : []

    content {
      capacity_reservation_target {
        capacity_reservation_id = var.capacity_reservation_id
      }
    }
  }

  # Disable API termination
  disable_api_termination = var.disable_api_termination

  # Instance initiated shutdown behavior
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  # Tenancy
  tenancy = var.tenancy

  # Source/destination check
  source_dest_check = var.source_dest_check

  # Hibernation
  hibernation = var.hibernation

  # Tags
  tags = merge(
    var.tags,
    {
      Name  = "${var.instance_name}-${count.index + 1}"
      Index = count.index + 1
    }
  )

  volume_tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-${count.index + 1}-volume"
    }
  )

  # Lifecycle
  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      user_data_base64,
    ]
  }
}

# ============================================================================
# Elastic IP (Optional)
# ============================================================================

# Allocate Elastic IPs
resource "aws_eip" "this" {
  count = var.allocate_eip ? var.instance_count : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.instance_name}-${count.index + 1}-eip"
    }
  )
}

# Associate Elastic IPs with instances
resource "aws_eip_association" "this" {
  count = var.allocate_eip ? var.instance_count : 0

  instance_id   = aws_instance.this[count.index].id
  allocation_id = aws_eip.this[count.index].id
}

# ============================================================================
# CloudWatch Alarms (Optional)
# ============================================================================

# CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_cloudwatch_alarms ? var.instance_count : 0

  alarm_name          = "${var.instance_name}-${count.index + 1}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.this[count.index].id
  }

  tags = var.tags
}

# Status check failed alarm
resource "aws_cloudwatch_metric_alarm" "status_check" {
  count = var.enable_cloudwatch_alarms ? var.instance_count : 0

  alarm_name          = "${var.instance_name}-${count.index + 1}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 status checks"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.this[count.index].id
  }

  tags = var.tags
}

# ============================================================================
# Outputs
# ============================================================================
# Outputs are defined in outputs.tf
# ============================================================================
