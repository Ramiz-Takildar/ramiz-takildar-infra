#!/bin/bash
# ============================================================================
# DynamoDB State Lock Table Setup Script
# ============================================================================
# This script creates a DynamoDB table for Terraform state locking.
#
# Prerequisites:
# - AWS CLI installed and configured
# - Appropriate IAM permissions to create DynamoDB tables
# - AWS credentials configured (via OIDC, environment variables, or AWS CLI)
#
# Usage:
#   ./setup-dynamodb.sh [table-name] [region]
#
# Examples:
#   ./setup-dynamodb.sh terraform-locks us-east-1
#   ./setup-dynamodb.sh terraform-state-locks eu-west-1
#
# Features:
# - Creates DynamoDB table with on-demand billing
# - Enables point-in-time recovery
# - Adds encryption at rest
# - Configures appropriate tags
# - Idempotent (safe to run multiple times)
# ============================================================================

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Default values
DEFAULT_TABLE_NAME="terraform-locks"
DEFAULT_REGION="us-east-1"

# Get parameters or use defaults
TABLE_NAME="${1:-$DEFAULT_TABLE_NAME}"
REGION="${2:-$DEFAULT_REGION}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        log_info "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity --region "$REGION" &> /dev/null; then
        log_error "AWS credentials are not configured or invalid."
        log_info "Configure credentials using: aws configure"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

check_table_exists() {
    log_info "Checking if DynamoDB table '$TABLE_NAME' exists..."
    
    if aws dynamodb describe-table \
        --table-name "$TABLE_NAME" \
        --region "$REGION" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

create_dynamodb_table() {
    log_info "Creating DynamoDB table: $TABLE_NAME in region: $REGION"
    
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" \
        --tags \
            Key=Name,Value="$TABLE_NAME" \
            Key=Purpose,Value="Terraform State Locking" \
            Key=ManagedBy,Value="Terraform" \
            Key=Platform,Value="AWS-Infrastructure-Platform" \
            Key=CreatedBy,Value="setup-dynamodb.sh" \
            Key=Environment,Value="shared" \
        --sse-specification Enabled=true,SSEType=KMS \
        > /dev/null
    
    log_success "DynamoDB table created successfully"
}

enable_point_in_time_recovery() {
    log_info "Enabling point-in-time recovery..."
    
    aws dynamodb update-continuous-backups \
        --table-name "$TABLE_NAME" \
        --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
        --region "$REGION" \
        > /dev/null
    
    log_success "Point-in-time recovery enabled"
}

wait_for_table_active() {
    log_info "Waiting for table to become active..."
    
    aws dynamodb wait table-exists \
        --table-name "$TABLE_NAME" \
        --region "$REGION"
    
    log_success "Table is now active"
}

display_table_info() {
    log_info "Retrieving table information..."
    
    TABLE_ARN=$(aws dynamodb describe-table \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Table.TableArn' \
        --output text)
    
    TABLE_STATUS=$(aws dynamodb describe-table \
        --table-name "$TABLE_NAME" \
        --region "$REGION" \
        --query 'Table.TableStatus' \
        --output text)
    
    echo ""
    echo "============================================================================"
    echo "DynamoDB Table Information"
    echo "============================================================================"
    echo "Table Name:   $TABLE_NAME"
    echo "Region:       $REGION"
    echo "Status:       $TABLE_STATUS"
    echo "ARN:          $TABLE_ARN"
    echo "Billing Mode: PAY_PER_REQUEST"
    echo "Encryption:   KMS (at rest)"
    echo "PITR:         Enabled"
    echo "============================================================================"
    echo ""
}

display_usage_instructions() {
    echo "============================================================================"
    echo "Next Steps"
    echo "============================================================================"
    echo ""
    echo "1. Update your Terraform backend configuration:"
    echo ""
    echo "   terraform {"
    echo "     backend \"s3\" {"
    echo "       bucket         = \"ramiz-takildar-infra\""
    echo "       key            = \"<environment>/<service>/terraform.tfstate\""
    echo "       region         = \"us-east-1\""
    echo "       dynamodb_table = \"$TABLE_NAME\""
    echo "       encrypt        = true"
    echo "     }"
    echo "   }"
    echo ""
    echo "2. Initialize Terraform with the backend:"
    echo ""
    echo "   terraform init \\"
    echo "     -backend-config=\"bucket=ramiz-takildar-infra\" \\"
    echo "     -backend-config=\"key=dev/ec2/terraform.tfstate\" \\"
    echo "     -backend-config=\"region=us-east-1\" \\"
    echo "     -backend-config=\"dynamodb_table=$TABLE_NAME\""
    echo ""
    echo "3. Verify state locking is working:"
    echo ""
    echo "   terraform plan"
    echo ""
    echo "============================================================================"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    echo ""
    echo "============================================================================"
    echo "DynamoDB State Lock Table Setup"
    echo "============================================================================"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Check if table already exists
    if check_table_exists; then
        log_warning "DynamoDB table '$TABLE_NAME' already exists in region '$REGION'"
        display_table_info
        log_info "Skipping table creation"
        exit 0
    fi
    
    # Create the table
    create_dynamodb_table
    
    # Wait for table to be active
    wait_for_table_active
    
    # Enable point-in-time recovery
    enable_point_in_time_recovery
    
    # Display table information
    display_table_info
    
    # Display usage instructions
    display_usage_instructions
    
    log_success "Setup completed successfully!"
}

# Run main function
main "$@"

# ============================================================================
# Troubleshooting
# ============================================================================
#
# Error: "An error occurred (ResourceInUseException)"
# Solution: Table already exists. Use a different table name or delete the
#           existing table first.
#
# Error: "An error occurred (AccessDeniedException)"
# Solution: Ensure your IAM user/role has the following permissions:
#           - dynamodb:CreateTable
#           - dynamodb:DescribeTable
#           - dynamodb:UpdateContinuousBackups
#           - dynamodb:TagResource
#
# Error: "Unable to locate credentials"
# Solution: Configure AWS credentials using:
#           - aws configure
#           - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#           - IAM role (for EC2 instances)
#           - OIDC (for GitHub Actions)
#
# ============================================================================
