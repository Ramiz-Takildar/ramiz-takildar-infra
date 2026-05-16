# ============================================================================
# VPC Module - Outputs
# ============================================================================
# This file defines all output values from the VPC module.
# Outputs are organized by category for better readability.
# ============================================================================

# ============================================================================
# VPC Outputs
# ============================================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = aws_vpc.this.default_network_acl_id
}

output "vpc_default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled"
  value       = aws_vpc.this.enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled"
  value       = aws_vpc.this.enable_dns_hostnames
}

# ============================================================================
# Subnet Outputs
# ============================================================================

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_availability_zones" {
  description = "List of availability zones of public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_availability_zones" {
  description = "List of availability zones of private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "database_subnet_ids" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnet_cidr_blocks" {
  description = "List of CIDR blocks of database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_availability_zones" {
  description = "List of availability zones of database subnets"
  value       = aws_subnet.database[*].availability_zone
}

output "database_subnet_group_id" {
  description = "ID of database subnet group"
  value       = var.create_database_subnets && var.create_database_subnet_group ? aws_db_subnet_group.this[0].id : null
}

output "database_subnet_group_arn" {
  description = "ARN of database subnet group"
  value       = var.create_database_subnets && var.create_database_subnet_group ? aws_db_subnet_group.this[0].arn : null
}

# ============================================================================
# Internet Gateway Outputs
# ============================================================================

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
}

output "internet_gateway_arn" {
  description = "The ARN of the Internet Gateway"
  value       = var.create_internet_gateway ? aws_internet_gateway.this[0].arn : null
}

# ============================================================================
# NAT Gateway Outputs
# ============================================================================

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs created for NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_allocation_ids" {
  description = "List of Elastic IP allocation IDs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

# ============================================================================
# Route Table Outputs
# ============================================================================

output "public_route_table_id" {
  description = "ID of public route table"
  value       = var.create_public_subnets ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = aws_route_table.database[*].id
}

# ============================================================================
# VPC Endpoint Outputs
# ============================================================================

output "s3_endpoint_id" {
  description = "ID of S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].prefix_list_id : null
}

output "dynamodb_endpoint_id" {
  description = "ID of DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "dynamodb_endpoint_prefix_list_id" {
  description = "Prefix list ID of DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].prefix_list_id : null
}

# ============================================================================
# VPC Flow Logs Outputs
# ============================================================================

output "flow_log_id" {
  description = "ID of VPC Flow Log"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_log_cloudwatch_log_group_name" {
  description = "Name of CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs && var.flow_logs_destination_arn == "" ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs && var.flow_logs_destination_arn == "" ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

# ============================================================================
# Availability Zones
# ============================================================================

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

output "availability_zones_count" {
  description = "Number of availability zones used"
  value       = local.max_azs
}

# ============================================================================
# Summary Output
# ============================================================================

output "vpc_summary" {
  description = "Summary of VPC configuration"
  value = {
    vpc_id                     = aws_vpc.this.id
    vpc_cidr                   = aws_vpc.this.cidr_block
    availability_zones         = local.azs
    public_subnet_ids          = aws_subnet.public[*].id
    private_subnet_ids         = aws_subnet.private[*].id
    database_subnet_ids        = aws_subnet.database[*].id
    nat_gateway_count          = length(aws_nat_gateway.this)
    internet_gateway_id        = var.create_internet_gateway ? aws_internet_gateway.this[0].id : null
    flow_logs_enabled          = var.enable_flow_logs
    s3_endpoint_enabled        = var.enable_s3_endpoint
    dynamodb_endpoint_enabled  = var.enable_dynamodb_endpoint
  }
}

# ============================================================================
# Network Configuration for Other Modules
# ============================================================================

output "network_configuration" {
  description = "Network configuration for use in other modules"
  value = {
    vpc_id                 = aws_vpc.this.id
    vpc_cidr               = aws_vpc.this.cidr_block
    public_subnet_ids      = aws_subnet.public[*].id
    private_subnet_ids     = aws_subnet.private[*].id
    database_subnet_ids    = aws_subnet.database[*].id
    database_subnet_group  = var.create_database_subnets && var.create_database_subnet_group ? aws_db_subnet_group.this[0].id : null
    availability_zones     = local.azs
  }
}

# ============================================================================
# Output Usage Examples
# ============================================================================
#
# Access outputs in root module:
# -------------------------------
# module "vpc" {
#   source = "./modules/vpc"
#   # ... configuration ...
# }
#
# output "vpc_id" {
#   value = module.vpc.vpc_id
# }
#
# output "private_subnet_ids" {
#   value = module.vpc.private_subnet_ids
# }
#
# Use outputs in other modules:
# ------------------------------
# module "ec2" {
#   source = "./modules/ec2"
#   
#   vpc_id     = module.vpc.vpc_id
#   subnet_ids = module.vpc.private_subnet_ids
# }
#
# module "rds" {
#   source = "./modules/rds"
#   
#   vpc_id            = module.vpc.vpc_id
#   subnet_group_name = module.vpc.database_subnet_group_id
# }
#
# Access in GitHub Actions:
# -------------------------
# - name: Get VPC ID
#   run: |
#     VPC_ID=$(terraform output -raw vpc_id)
#     echo "VPC ID: $VPC_ID"
#
# - name: Get Subnet IDs
#   run: |
#     SUBNET_IDS=$(terraform output -json private_subnet_ids | jq -r '.[]')
#     echo "Subnet IDs: $SUBNET_IDS"
#
# ============================================================================
