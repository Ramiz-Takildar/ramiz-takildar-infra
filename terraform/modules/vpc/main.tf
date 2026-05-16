# ============================================================================
# VPC Module - Main Configuration
# ============================================================================
# This module creates a complete VPC infrastructure with:
# - VPC with custom CIDR
# - Public and private subnets across multiple AZs
# - Internet Gateway for public subnets
# - NAT Gateways for private subnets (optional)
# - Route tables and associations
# - Network ACLs
# - VPC Flow Logs
# - VPC Endpoints
# - DHCP Options
# - DNS support
#
# High Availability:
# - Multi-AZ deployment
# - Redundant NAT Gateways (optional)
# - Automatic subnet distribution
# ============================================================================

# ============================================================================
# Data Sources
# ============================================================================

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current region
data "aws_region" "current" {}

# Get current account ID
data "aws_caller_identity" "current" {}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Calculate number of AZs to use
  max_azs = min(var.max_availability_zones, length(data.aws_availability_zones.available.names))
  azs     = slice(data.aws_availability_zones.available.names, 0, local.max_azs)

  # Calculate subnet CIDRs
  public_subnet_cidrs  = [for i in range(local.max_azs) : cidrsubnet(var.vpc_cidr, var.public_subnet_bits, i)]
  private_subnet_cidrs = [for i in range(local.max_azs) : cidrsubnet(var.vpc_cidr, var.private_subnet_bits, i + local.max_azs)]
  database_subnet_cidrs = var.create_database_subnets ? [for i in range(local.max_azs) : cidrsubnet(var.vpc_cidr, var.database_subnet_bits, i + (2 * local.max_azs))] : []

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Name      = var.vpc_name
      ManagedBy = "Terraform"
    }
  )
}

# ============================================================================
# VPC
# ============================================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    local.common_tags,
    {
      Name = var.vpc_name
    }
  )
}

# ============================================================================
# DHCP Options
# ============================================================================

resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-dhcp-options"
    }
  )
}

resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# ============================================================================
# Internet Gateway
# ============================================================================

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

# ============================================================================
# Public Subnets
# ============================================================================

resource "aws_subnet" "public" {
  count = var.create_public_subnets ? local.max_azs : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-public-${local.azs[count.index]}"
      Type = "public"
      Tier = "public"
    },
    var.public_subnet_tags
  )
}

# ============================================================================
# Private Subnets
# ============================================================================

resource "aws_subnet" "private" {
  count = var.create_private_subnets ? local.max_azs : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-private-${local.azs[count.index]}"
      Type = "private"
      Tier = "private"
    },
    var.private_subnet_tags
  )
}

# ============================================================================
# Database Subnets
# ============================================================================

resource "aws_subnet" "database" {
  count = var.create_database_subnets ? local.max_azs : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.database_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-database-${local.azs[count.index]}"
      Type = "database"
      Tier = "database"
    },
    var.database_subnet_tags
  )
}

# Database subnet group
resource "aws_db_subnet_group" "this" {
  count = var.create_database_subnets && var.create_database_subnet_group ? 1 : 0

  name       = "${var.vpc_name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-db-subnet-group"
    }
  )
}

# ============================================================================
# Elastic IPs for NAT Gateways
# ============================================================================

resource "aws_eip" "nat" {
  count = var.create_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# ============================================================================
# NAT Gateways
# ============================================================================

resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-nat-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

# ============================================================================
# Route Tables
# ============================================================================

# Public route table
resource "aws_route_table" "public" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-public-rt"
      Type = "public"
    }
  )
}

# Public route to Internet Gateway
resource "aws_route" "public_internet_gateway" {
  count = var.create_public_subnets && var.create_internet_gateway ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

# Public route table associations
resource "aws_route_table_association" "public" {
  count = var.create_public_subnets ? local.max_azs : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Private route tables
resource "aws_route_table" "private" {
  count = var.create_private_subnets ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = var.single_nat_gateway ? "${var.vpc_name}-private-rt" : "${var.vpc_name}-private-rt-${local.azs[count.index]}"
      Type = "private"
    }
  )
}

# Private route to NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count = var.create_private_subnets && var.create_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

# Private route table associations
resource "aws_route_table_association" "private" {
  count = var.create_private_subnets ? local.max_azs : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

# Database route tables
resource "aws_route_table" "database" {
  count = var.create_database_subnets && var.create_database_route_table ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = var.single_nat_gateway ? "${var.vpc_name}-database-rt" : "${var.vpc_name}-database-rt-${local.azs[count.index]}"
      Type = "database"
    }
  )
}

# Database route to NAT Gateway
resource "aws_route" "database_nat_gateway" {
  count = var.create_database_subnets && var.create_database_route_table && var.create_nat_gateway ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id

  timeouts {
    create = "5m"
  }
}

# Database route table associations
resource "aws_route_table_association" "database" {
  count = var.create_database_subnets && var.create_database_route_table ? local.max_azs : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.database[0].id : aws_route_table.database[count.index].id
}

# ============================================================================
# VPC Flow Logs
# ============================================================================

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = var.flow_logs_traffic_type
  iam_role_arn    = var.flow_logs_iam_role_arn != "" ? var.flow_logs_iam_role_arn : aws_iam_role.flow_logs[0].arn
  log_destination = var.flow_logs_destination_arn != "" ? var.flow_logs_destination_arn : aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-flow-logs"
    }
  )
}

# CloudWatch Log Group for Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_destination_arn == "" ? 1 : 0

  name              = "/aws/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = local.common_tags
}

# IAM Role for Flow Logs
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_iam_role_arn == "" ? 1 : 0

  name = "${var.vpc_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Flow Logs
resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs && var.flow_logs_iam_role_arn == "" ? 1 : 0

  name = "${var.vpc_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# VPC Endpoints
# ============================================================================

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-s3-endpoint"
    }
  )
}

# S3 Endpoint Route Table Associations
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  count = var.enable_s3_endpoint && var.create_private_subnets ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-dynamodb-endpoint"
    }
  )
}

# DynamoDB Endpoint Route Table Associations
resource "aws_vpc_endpoint_route_table_association" "dynamodb_private" {
  count = var.enable_dynamodb_endpoint && var.create_private_subnets ? (var.single_nat_gateway ? 1 : local.max_azs) : 0

  route_table_id  = aws_route_table.private[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}

#============================================================================
# Default Security Group
# ============================================================================

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  # Remove all default rules
  ingress = []
  egress  = []

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-default-sg"
    }
  )
}

# ============================================================================
# Default Network ACL
# ============================================================================

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  # Remove all default rules for security
  ingress = []
  egress  = []

  tags = merge(
    local.common_tags,
    {
      Name = "${var.vpc_name}-default-nacl"
    }
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

# ============================================================================
# Outputs
# ============================================================================
# Outputs are defined in outputs.tf
# ============================================================================
