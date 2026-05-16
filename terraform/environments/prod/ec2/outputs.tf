output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = module.ec2.instance_arns
}

output "instance_public_ips" {
  description = "List of public IP addresses"
  value       = module.ec2.instance_public_ips
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = module.ec2.instance_private_ips
}

output "instance_public_dns" {
  description = "List of public DNS names"
  value       = module.ec2.instance_public_dns
}

output "instance_private_dns" {
  description = "List of private DNS names"
  value       = module.ec2.instance_private_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.ec2.security_group_id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.ec2.iam_role_arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = module.ec2.iam_instance_profile_arn
}
