# ============================================================================
# Terraform Backend Configuration File (HCL)
# ============================================================================
# This file provides backend configuration values that can be passed to
# terraform init using the -backend-config flag.
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# Or for dynamic configuration:
#   terraform init \
#     -backend-config="bucket=ramiz-takildar-infra" \
#     -backend-config="key=${ENVIRONMENT}/${SERVICE}/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="dynamodb_table=terraform-locks"
#
# This approach allows for:
# - Environment-specific state files
# - Service-specific state files
# - Dynamic backend configuration in CI/CD pipelines
# ============================================================================

# S3 bucket name for Terraform state storage
bucket = "ramiz-takildar-infra"

# State file key (path within the bucket)
# This should be overridden per environment/service
# Format: {environment}/{service}/terraform.tfstate
key = "terraform.tfstate"

# AWS region where the S3 bucket is located
region = "us-east-1"

# DynamoDB table for state locking
dynamodb_table = "terraform-locks"

# Enable encryption for state files
encrypt = true

# ACL for state files
acl = "private"

# Workspace key prefix
workspace_key_prefix = "workspaces"

# ============================================================================
# Environment-Specific Backend Configuration Examples
# ============================================================================
#
# Development Environment - EC2:
# ------------------------------
# bucket         = "ramiz-takildar-infra"
# key            = "dev/ec2/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-locks"
# encrypt        = true
#
# Staging Environment - VPC:
# --------------------------
# bucket         = "ramiz-takildar-infra"
# key            = "staging/vpc/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-locks"
# encrypt        = true
#
# Production Environment - EKS:
# -----------------------------
# bucket         = "ramiz-takildar-infra"
# key            = "prod/eks/terraform.tfstate"
# region         = "us-east-1"
# dynamodb_table = "terraform-locks"
# encrypt        = true
#
# ============================================================================
# Dynamic Backend Configuration in CI/CD
# ============================================================================
#
# GitHub Actions Example:
# -----------------------
# - name: Initialize Terraform
#   run: |
#     terraform init \
#       -backend-config="bucket=ramiz-takildar-infra" \
#       -backend-config="key=${{ inputs.environment }}/${{ inputs.service }}/terraform.tfstate" \
#       -backend-config="region=us-east-1" \
#       -backend-config="dynamodb_table=terraform-locks" \
#       -backend-config="encrypt=true"
#
# Shell Script Example:
# ---------------------
# #!/bin/bash
# ENVIRONMENT=$1
# SERVICE=$2
#
# terraform init \
#   -backend-config="bucket=ramiz-takildar-infra" \
#   -backend-config="key=${ENVIRONMENT}/${SERVICE}/terraform.tfstate" \
#   -backend-config="region=us-east-1" \
#   -backend-config="dynamodb_table=terraform-locks"
#
# ============================================================================
