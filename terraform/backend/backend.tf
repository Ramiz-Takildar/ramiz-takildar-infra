# ============================================================================
# Terraform Backend Configuration
# ============================================================================
# This file defines the S3 backend configuration for storing Terraform state
# remotely with DynamoDB for state locking.
#
# Backend Configuration:
# - S3 Bucket: ramiz-takildar-infra (existing bucket in us-east-1)
# - DynamoDB Table: terraform-locks (for state locking)
# - Encryption: AES256 (server-side encryption)
# - Versioning: Enabled on S3 bucket
#
# Usage:
#   terraform init -backend-config=backend.hcl
# ============================================================================

terraform {
  backend "s3" {
    # S3 bucket for storing Terraform state
    # This bucket must exist before running terraform init
    bucket = "ramiz-takildar-infra"
    
    # State file path - dynamically set per environment/service
    # Format: {environment}/{service}/terraform.tfstate
    # Example: dev/ec2/terraform.tfstate
    key = "terraform.tfstate"
    
    # AWS region where the S3 bucket is located
    region = "us-east-1"
    
    # DynamoDB table for state locking
    # Prevents concurrent modifications to the same state file
    dynamodb_table = "terraform-locks"
    
    # Enable server-side encryption for state files
    encrypt = true
    
    # Workspace key prefix for multi-workspace support
    workspace_key_prefix = "workspaces"
    
    # Additional security settings
    acl = "private"
    
    # Skip credentials validation (useful for CI/CD)
    skip_credentials_validation = false
    skip_metadata_api_check     = false
    skip_region_validation      = false
  }
}

# ============================================================================
# Backend Configuration Notes
# ============================================================================
#
# State File Isolation Strategy:
# ------------------------------
# Each environment and service combination gets its own state file:
#
# Development:
#   - dev/ec2/terraform.tfstate
#   - dev/s3/terraform.tfstate
#   - dev/vpc/terraform.tfstate
#   - dev/eks/terraform.tfstate
#
# Staging:
#   - staging/ec2/terraform.tfstate
#   - staging/s3/terraform.tfstate
#   - staging/vpc/terraform.tfstate
#
# Production:
#   - prod/ec2/terraform.tfstate
#   - prod/s3/terraform.tfstate
#   - prod/vpc/terraform.tfstate
#
# Benefits:
# ---------
# 1. Environment Isolation: Changes in dev don't affect prod
# 2. Service Isolation: EC2 changes don't affect VPC state
# 3. Parallel Execution: Multiple teams can work simultaneously
# 4. Blast Radius Reduction: Errors are contained to specific services
# 5. Easier Rollbacks: Revert specific service without affecting others
#
# State Locking:
# --------------
# DynamoDB table prevents concurrent state modifications:
# - Lock acquired before terraform apply/destroy
# - Lock released after operation completes
# - Prevents state corruption from simultaneous runs
#
# Encryption:
# -----------
# - Server-side encryption (AES256) enabled by default
# - Optional: Use KMS for additional key management
# - State files contain sensitive data (passwords, keys)
#
# ============================================================================
