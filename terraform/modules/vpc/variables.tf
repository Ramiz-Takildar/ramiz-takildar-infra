# ============================================================================
# VPC Module - Variables
# ============================================================================
# This file defines all input variables for the VPC module.
# Variables are organized by category for better readability.
# ============================================================================

# ============================================================================
# General Configuration
# ============================================================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vpc_name))
    error_message = "VPC name must contain only alphanumeric characters and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "Tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be either default or dedicated."
  }
}

# ============================================================================
# Availability Zones
# ============================================================================

variable "max_availability_zones" {
  description = "Maximum number of availability zones to use"
  type        = number
  default     = 3

  validation {
    condition     = var.max_availability_zones >= 1 && var.max_availability_zones <= 6
    error_message = "Maximum availability zones must be between 1 and 6."
  }
}

# ============================================================================
# Subnet Configuration
# ============================================================================

variable "create_public_subnets" {
  description = "Create public subnets"
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = true
}

variable "create_database_subnets" {
  description = "Create database subnets"
  type        = bool
  default     = false
}

variable "public_subnet_bits" {
  description = "Number of bits to add to VPC CIDR for public subnets"
  type        = number
  default     = 8

  validation {
    condition     = var.public_subnet_bits >= 1 && var.public_subnet_bits <= 16
    error_message = "Public subnet bits must be between 1 and 16."
  }
}

variable "private_subnet_bits" {
  description = "Number of bits to add to VPC CIDR for private subnets"
  type        = number
  default     = 8

  validation {
    condition     = var.private_subnet_bits >= 1 && var.private_subnet_bits <= 16
    error_message = "Private subnet bits must be between 1 and 16."
  }
}

variable "database_subnet_bits" {
  description = "Number of bits to add to VPC CIDR for database subnets"
  type        = number
  default     = 8

  validation {
    condition     = var.database_subnet_bits >= 1 && var.database_subnet_bits <= 16
    error_message = "Database subnet bits must be between 1 and 16."
  }
}

variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP on launch for public subnets"
  type        = bool
  default     = true
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "database_subnet_tags" {
  description = "Additional tags for database subnets"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Internet Gateway Configuration
# ============================================================================

variable "create_internet_gateway" {
  description = "Create an Internet Gateway for the VPC"
  type        = bool
  default     = true
}

# ============================================================================
# NAT Gateway Configuration
# ============================================================================

variable "create_nat_gateway" {
  description = "Create NAT Gateways for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization)"
  type        = bool
  default     = false
}

# ============================================================================
# Route Table Configuration
# ============================================================================

variable "create_database_route_table" {
  description = "Create separate route table for database subnets"
  type        = bool
  default     = false
}

# ============================================================================
# Database Subnet Group
# ============================================================================

variable "create_database_subnet_group" {
  description = "Create database subnet group for RDS"
  type        = bool
  default     = true
}

# ============================================================================
# DHCP Options
# ============================================================================

variable "enable_dhcp_options" {
  description = "Enable custom DHCP options"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "List of name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "List of NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = number
  default     = 2
}

# ============================================================================
# VPC Flow Logs
# ============================================================================

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to log (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_destination_arn" {
  description = "ARN of the destination for flow logs (CloudWatch Logs or S3)"
  type        = string
  default     = ""
}

variable "flow_logs_iam_role_arn" {
  description = "ARN of IAM role for flow logs"
  type        = string
  default     = ""
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_logs_retention_days)
    error_message = "Flow logs retention days must be a valid CloudWatch Logs retention period."
  }
}

# ============================================================================
# VPC Endpoints
# ============================================================================

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB VPC endpoint"
  type        = bool
  default     = false
}

# ============================================================================
# Variable Usage Examples
# ============================================================================
#
# Basic VPC:
# ----------
# vpc_name = "production-vpc"
# vpc_cidr = "10.0.0.0/16"
# max_availability_zones = 3
#
# VPC with Custom Subnets:
# ------------------------
# vpc_name = "app-vpc"
# vpc_cidr = "10.1.0.0/16"
# public_subnet_bits = 8   # /24 subnets
# private_subnet_bits = 8  # /24 subnets
# create_database_subnets = true
# database_subnet_bits = 8 # /24 subnets
#
# Cost-Optimized VPC:
# -------------------
# vpc_name = "dev-vpc"
# vpc_cidr = "10.2.0.0/16"
# single_nat_gateway = true  # Use single NAT Gateway
# max_availability_zones = 2 # Use only 2 AZs
#
# High-Availability VPC:
# ----------------------
# vpc_name = "prod-vpc"
# vpc_cidr = "10.0.0.0/16"
# max_availability_zones = 3
# single_nat_gateway = false # NAT Gateway per AZ
# enable_flow_logs = true
# enable_s3_endpoint = true
# enable_dynamodb_endpoint = true
#
# VPC with Flow Logs:
# -------------------
# vpc_name = "secure-vpc"
# vpc_cidr = "10.3.0.0/16"
# enable_flow_logs = true
# flow_logs_traffic_type = "ALL"
# flow_logs_retention_days = 30
#
# VPC with Database Subnets:
# ---------------------------
# vpc_name = "data-vpc"
# vpc_cidr = "10.4.0.0/16"
# create_database_subnets = true
# create_database_subnet_group = true
# create_database_route_table = true
#
# ============================================================================
# CIDR Calculation Examples
# ============================================================================
#
# VPC CIDR: 10.0.0.0/16 (65,536 IPs)
# Subnet Bits: 8
# Result: /24 subnets (256 IPs each)
#
# With 3 AZs:
# - Public Subnets:
#   - 10.0.0.0/24 (AZ-1)
#   - 10.0.1.0/24 (AZ-2)
#   - 10.0.2.0/24 (AZ-3)
# - Private Subnets:
#   - 10.0.3.0/24 (AZ-1)
#   - 10.0.4.0/24 (AZ-2)
#   - 10.0.5.0/24 (AZ-3)
# - Database Subnets:
#   - 10.0.6.0/24 (AZ-1)
#   - 10.0.7.0/24 (AZ-2)
#   - 10.0.8.0/24 (AZ-3)
#
# ============================================================================
# Best Practices
# ============================================================================
#
# 1. CIDR Planning:
#    - Use RFC 1918 private address space
#    - Plan for future growth
#    - Avoid overlapping with on-premises networks
#    - Common VPC CIDRs: /16 (65,536 IPs), /20 (4,096 IPs)
#
# 2. Subnet Design:
#    - Use multiple AZs for high availability
#    - Separate public, private, and database subnets
#    - Size subnets appropriately for workload
#    - Reserve space for future subnets
#
# 3. NAT Gateway:
#    - Use one NAT Gateway per AZ for HA
#    - Use single NAT Gateway for dev/test (cost savings)
#    - Consider NAT instances for very low traffic
#
# 4. Security:
#    - Enable VPC Flow Logs for audit and troubleshooting
#    - Use VPC endpoints to avoid internet traffic
#    - Implement network ACLs for additional security
#    - Use security groups for instance-level security
#
# 5. Cost Optimization:
#    - Use single NAT Gateway for non-production
#    - Reduce number of AZs for dev/test
#    - Use VPC endpoints to reduce NAT Gateway costs
#    - Monitor and optimize data transfer costs
#
# ============================================================================
