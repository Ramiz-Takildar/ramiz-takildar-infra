terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.30.0"
    }
  }

  backend "s3" {
    bucket         = "ramiz-takildar-infra"
    key            = "staging/eks/terraform.tfstate"
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
        Environment = "staging"
        ManagedBy   = "Terraform"
        Service     = "EKS"
      }
    )
  }
}

# EKS Module
module "eks" {
  source = "../../../modules/eks"

  # Cluster Configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  # VPC Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Node Group Configuration
  node_groups = var.node_groups

  # Fargate Configuration
  fargate_profiles   = var.fargate_profiles
  fargate_subnet_ids = var.fargate_subnet_ids

  # Security
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Monitoring
  cluster_enabled_log_types    = var.cluster_enabled_log_types
  performance_insights_enabled = var.performance_insights_enabled

  # Tags
  tags = var.tags
}
