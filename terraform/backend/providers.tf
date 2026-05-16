# ============================================================================
# Terraform Providers Configuration
# ============================================================================
# This file configures the required providers and their versions for the
# infrastructure platform.
#
# Providers:
# - AWS: Primary cloud provider for infrastructure resources
# - Random: For generating random values (passwords, IDs, etc.)
# - TLS: For generating SSH keys and certificates
# - Null: For provisioners and local-exec commands
#
# Version Constraints:
# - Terraform: >= 1.5.0 (for latest features and stability)
# - AWS Provider: ~> 5.0 (allows 5.x versions, prevents breaking changes)
# ============================================================================

terraform {
  # Minimum Terraform version required
  required_version = ">= 1.5.0"

  # Required providers with version constraints
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# ============================================================================
# AWS Provider Configuration
# ============================================================================
# The AWS provider is configured with default tags that will be applied to
# all resources created by Terraform.
#
# Authentication Methods (in order of precedence):
# 1. OIDC (GitHub Actions) - Recommended for CI/CD
# 2. Environment Variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
# 3. AWS CLI credentials (~/.aws/credentials)
# 4. IAM Instance Profile (for EC2 instances)
#
# Region Configuration:
# - Default region can be overridden via variables
# - Resources can be deployed to any AWS region
# - Backend always uses us-east-1 (centralized state)
# ============================================================================

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  # These tags help with cost tracking, compliance, and resource management
  default_tags {
    tags = {
      # Managed by Terraform
      ManagedBy = "Terraform"
      
      # Platform identifier
      Platform = "AWS-Infrastructure-Platform"
      
      # Environment (dev, staging, prod)
      Environment = var.environment
      
      # Service/Component name
      Service = var.service_name
      
      # Project identifier
      Project = var.project_name
      
      # Cost center for billing
      CostCenter = var.cost_center
      
      # Owner/Team responsible
      Owner = var.owner
      
      # Creation timestamp
      CreatedAt = timestamp()
      
      # Terraform workspace
      Workspace = terraform.workspace
      
      # Repository information
      Repository = var.repository_url
      
      # Compliance tags
      Compliance = var.compliance_tags
      
      # Data classification
      DataClassification = var.data_classification
    }
  }

  # Assume role configuration (optional)
  # Useful for cross-account deployments
  dynamic "assume_role" {
    for_each = var.assume_role_arn != "" ? [1] : []
    content {
      role_arn     = var.assume_role_arn
      session_name = "terraform-${var.environment}-${var.service_name}"
      external_id  = var.external_id
    }
  }

  # Ignore tags for resources managed outside Terraform
  ignore_tags {
    key_prefixes = var.ignore_tag_prefixes
  }

  # Retry configuration for API calls
  max_retries = 3

  # HTTP proxy configuration (if needed)
  # http_proxy  = var.http_proxy
  # https_proxy = var.https_proxy
  # no_proxy    = var.no_proxy
}

# ============================================================================
# AWS Provider Alias for Multi-Region Deployments
# ============================================================================
# Additional provider configurations for multi-region resources
# Example: Global services, cross-region replication, disaster recovery
# ============================================================================

# US East 1 (N. Virginia) - Primary region for global services
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Platform    = "AWS-Infrastructure-Platform"
      Environment = var.environment
      Service     = var.service_name
      Region      = "us-east-1"
    }
  }
}

# US West 2 (Oregon) - Secondary region for DR
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Platform    = "AWS-Infrastructure-Platform"
      Environment = var.environment
      Service     = var.service_name
      Region      = "us-west-2"
    }
  }
}

# EU West 1 (Ireland) - European region
provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Platform    = "AWS-Infrastructure-Platform"
      Environment = var.environment
      Service     = var.service_name
      Region      = "eu-west-1"
    }
  }
}

# ============================================================================
# Provider Configuration Variables
# ============================================================================
# These variables allow dynamic configuration of the AWS provider
# Values can be set via:
# - terraform.tfvars
# - Environment variables (TF_VAR_*)
# - Command line (-var)
# - GitHub Actions inputs
# ============================================================================

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, eu-west-1)."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "service_name" {
  description = "Name of the service being deployed"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.service_name))
    error_message = "Service name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-infrastructure-platform"
}

variable "cost_center" {
  description = "Cost center for billing and cost allocation"
  type        = string
  default     = "engineering"
}

variable "owner" {
  description = "Owner or team responsible for the resources"
  type        = string
  default     = "devops-team"
}

variable "repository_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/ramiz-takildar/ramiz-takildar-infra"
}

variable "compliance_tags" {
  description = "Compliance requirements (e.g., HIPAA, PCI-DSS, SOC2)"
  type        = string
  default     = "none"
}

variable "data_classification" {
  description = "Data classification level (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be one of: public, internal, confidential, restricted."
  }
}

variable "assume_role_arn" {
  description = "ARN of IAM role to assume for cross-account access"
  type        = string
  default     = ""
}

variable "external_id" {
  description = "External ID for assume role (additional security)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ignore_tag_prefixes" {
  description = "List of tag key prefixes to ignore"
  type        = list(string)
  default     = ["aws:", "kubernetes.io/"]
}

# ============================================================================
# Provider Configuration Best Practices
# ============================================================================
#
# 1. Version Pinning:
#    - Use ~> for minor version updates
#    - Test provider upgrades in dev first
#    - Review provider changelogs before upgrading
#
# 2. Authentication:
#    - Use OIDC for GitHub Actions (no long-lived credentials)
#    - Use IAM roles instead of access keys
#    - Rotate credentials regularly
#    - Never commit credentials to version control
#
# 3. Tagging Strategy:
#    - Use default_tags for consistent tagging
#    - Include environment, service, owner, cost center
#    - Add compliance and data classification tags
#    - Use tags for cost allocation and resource tracking
#
# 4. Multi-Region:
#    - Use provider aliases for multi-region deployments
#    - Keep backend in single region (us-east-1)
#    - Consider data residency requirements
#    - Plan for disaster recovery
#
# 5. Security:
#    - Enable encryption by default
#    - Use least privilege IAM policies
#    - Implement resource policies
#    - Enable CloudTrail logging
#    - Use AWS Config for compliance
#
# ============================================================================
