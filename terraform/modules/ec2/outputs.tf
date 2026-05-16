# ============================================================================
# EC2 Instance Module - Outputs
# ============================================================================
# This file defines all output values from the EC2 module.
# Outputs are organized by category for better readability.
# ============================================================================

# ============================================================================
# Instance Outputs
# ============================================================================

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.this[*].id
}

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = aws_instance.this[*].arn
}

output "instance_private_ips" {
  description = "List of private IP addresses assigned to the instances"
  value       = aws_instance.this[*].private_ip
}

output "instance_public_ips" {
  description = "List of public IP addresses assigned to the instances"
  value       = aws_instance.this[*].public_ip
}

output "instance_private_dns" {
  description = "List of private DNS names assigned to the instances"
  value       = aws_instance.this[*].private_dns
}

output "instance_public_dns" {
  description = "List of public DNS names assigned to the instances"
  value       = aws_instance.this[*].public_dns
}

output "instance_availability_zones" {
  description = "List of availability zones where instances are launched"
  value       = aws_instance.this[*].availability_zone
}

output "instance_subnet_ids" {
  description = "List of subnet IDs where instances are launched"
  value       = aws_instance.this[*].subnet_id
}

output "instance_state" {
  description = "List of instance states"
  value       = aws_instance.this[*].instance_state
}

output "instance_ami" {
  description = "AMI ID used for the instances"
  value       = var.ami_id != "" ? var.ami_id : data.aws_ami.selected.id
}

output "instance_type" {
  description = "Instance type used"
  value       = var.instance_type
}

# ============================================================================
# Elastic IP Outputs
# ============================================================================

output "eip_ids" {
  description = "List of Elastic IP allocation IDs"
  value       = var.allocate_eip ? aws_eip.this[*].id : []
}

output "eip_public_ips" {
  description = "List of Elastic IP addresses"
  value       = var.allocate_eip ? aws_eip.this[*].public_ip : []
}

output "eip_public_dns" {
  description = "List of Elastic IP public DNS names"
  value       = var.allocate_eip ? aws_eip.this[*].public_dns : []
}

# ============================================================================
# Security Group Outputs
# ============================================================================

output "security_group_id" {
  description = "ID of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_arn" {
  description = "ARN of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

output "security_group_name" {
  description = "Name of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].name : null
}

output "security_group_vpc_id" {
  description = "VPC ID of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].vpc_id : null
}

# ============================================================================
# IAM Outputs
# ============================================================================

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_iam_instance_profile ? aws_iam_role.this[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = var.create_iam_instance_profile ? aws_iam_role.this[0].name : null
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : null
}

# ============================================================================
# Key Pair Outputs
# ============================================================================

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_pair_name
}

output "key_pair_id" {
  description = "ID of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.this[0].id : null
}

output "key_pair_arn" {
  description = "ARN of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.this[0].arn : null
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the SSH key pair"
  value       = var.create_key_pair ? aws_key_pair.this[0].fingerprint : null
}

# ============================================================================
# CloudWatch Alarm Outputs
# ============================================================================

output "cpu_alarm_arns" {
  description = "List of CPU utilization alarm ARNs"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.cpu[*].arn : []
}

output "status_check_alarm_arns" {
  description = "List of status check alarm ARNs"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.status_check[*].arn : []
}

# ============================================================================
# Volume Outputs
# ============================================================================

output "root_block_device_volume_ids" {
  description = "List of root block device volume IDs"
  value       = aws_instance.this[*].root_block_device[0].volume_id
}

output "ebs_block_device_volume_ids" {
  description = "List of additional EBS block device volume IDs"
  value       = flatten([for instance in aws_instance.this : [for device in instance.ebs_block_device : device.volume_id]])
}

# ============================================================================
# Connection Information
# ============================================================================

output "ssh_connection_strings" {
  description = "SSH connection strings for the instances"
  value = [
    for i, instance in aws_instance.this : 
    "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${var.allocate_eip ? aws_eip.this[i].public_ip : instance.public_ip}"
  ]
}

output "ssm_connection_commands" {
  description = "AWS Systems Manager Session Manager connection commands"
  value = [
    for instance in aws_instance.this :
    "aws ssm start-session --target ${instance.id}"
  ]
}

# ============================================================================
# Summary Output
# ============================================================================

output "instance_summary" {
  description = "Summary of all created instances"
  value = {
    count               = var.instance_count
    instance_type       = var.instance_type
    ami_id              = var.ami_id != "" ? var.ami_id : data.aws_ami.selected.id
    instance_ids        = aws_instance.this[*].id
    private_ips         = aws_instance.this[*].private_ip
    public_ips          = aws_instance.this[*].public_ip
    availability_zones  = aws_instance.this[*].availability_zone
    security_group_id   = var.create_security_group ? aws_security_group.this[0].id : null
    key_pair_name       = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_pair_name
    iam_instance_profile = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile_name
  }
}

# ============================================================================
# Output Usage Examples
# ============================================================================
#
# Access outputs in root module:
# -------------------------------
# module "ec2" {
#   source = "./modules/ec2"
#   # ... configuration ...
# }
#
# output "instance_ids" {
#   value = module.ec2.instance_ids
# }
#
# output "instance_public_ips" {
#   value = module.ec2.instance_public_ips
# }
#
# Use outputs in other resources:
# --------------------------------
# resource "aws_route53_record" "web" {
#   count   = length(module.ec2.instance_public_ips)
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "web-${count.index + 1}.example.com"
#   type    = "A"
#   ttl     = 300
#   records = [module.ec2.instance_public_ips[count.index]]
# }
#
# Access in GitHub Actions:
# -------------------------
# - name: Get Instance IDs
#   run: |
#     INSTANCE_IDS=$(terraform output -json instance_ids | jq -r '.[]')
#     echo "Instance IDs: $INSTANCE_IDS"
#
# ============================================================================
