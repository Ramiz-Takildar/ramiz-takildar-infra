terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "ramiz-takildar-infra"
    key            = "prod/vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = "prod"
        ManagedBy   = "Terraform"
        Service     = "VPC"
      }
    )
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "../../../modules/vpc"
  
  # VPC Configuration
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  
  # Availability Zones
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, var.max_availability_zones)
  max_availability_zones = var.max_availability_zones
  
  # Subnets
  create_public_subnets   = var.create_public_subnets
  create_private_subnets  = var.create_private_subnets
  create_database_subnets = var.create_database_subnets
  
  # NAT Gateway
  create_nat_gateway = var.create_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  
  # Internet Gateway
  create_internet_gateway = var.create_internet_gateway
  
  # VPC Features
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  
  # Flow Logs
  enable_flow_logs           = var.enable_flow_logs
  flow_logs_traffic_type     = var.flow_logs_traffic_type
  flow_logs_retention_days   = var.flow_logs_retention_days
  
  # VPC Endpoints
  enable_s3_endpoint       = var.enable_s3_endpoint
  enable_dynamodb_endpoint = var.enable_dynamodb_endpoint
  
  # Tags
  tags = var.tags
}
