# First-Time Setup Guide

> **Complete guide for setting up the AWS Infrastructure Provisioning Platform from scratch**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [AWS Account Setup](#aws-account-setup)
4. [GitHub Repository Setup](#github-repository-setup)
5. [OIDC Authentication Setup](#oidc-authentication-setup)
6. [Backend Configuration](#backend-configuration)
7. [GitHub Secrets Configuration](#github-secrets-configuration)
8. [Verify Setup](#verify-setup)
9. [Deploy Your First Resource](#deploy-your-first-resource)
10. [Troubleshooting](#troubleshooting)

## Overview

This guide will help you set up the infrastructure platform in **30-45 minutes**. You'll configure:

- ✅ AWS account and IAM permissions
- ✅ GitHub OIDC authentication (no access keys needed!)
- ✅ Terraform backend (S3 + DynamoDB)
- ✅ GitHub Actions workflows
- ✅ Security scanning tools

**What You'll Need**:
- AWS account with admin access
- GitHub account
- AWS CLI installed
- Terraform installed (optional, for local testing)

## Prerequisites

### 1. Install Required Tools

#### AWS CLI
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Windows
# Download from: https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify installation
aws --version
```

#### Terraform (Optional)
```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Windows
# Download from: https://www.terraform.io/downloads

# Verify installation
terraform --version
```

#### Git
```bash
# macOS
brew install git

# Linux
sudo apt-get install git  # Ubuntu/Debian
sudo yum install git      # RHEL/CentOS

# Windows
# Download from: https://git-scm.com/download/win

# Verify installation
git --version
```

### 2. Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Enter your credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

**Expected Output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

## AWS Account Setup

### Step 1: Create IAM User (If Needed)

If you don't have an IAM user with admin access:

```bash
# Create IAM user
aws iam create-user --user-name terraform-admin

# Attach admin policy
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name terraform-admin
```

**Save the output** - you'll need these credentials!

### Step 2: Note Your AWS Account ID

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID: $AWS_ACCOUNT_ID"

# Save this - you'll need it later!
```

## GitHub Repository Setup

### Step 1: Fork or Clone Repository

**Option A: Fork the Repository** (Recommended)
1. Go to the repository on GitHub
2. Click **"Fork"** button
3. Clone your fork:
```bash
git clone https://github.com/YOUR_USERNAME/ramiz-takildar-infra.git
cd ramiz-takildar-infra
```

**Option B: Use as Template**
1. Click **"Use this template"** button
2. Create new repository
3. Clone your repository:
```bash
git clone https://github.com/YOUR_USERNAME/your-infra-repo.git
cd your-infra-repo
```

### Step 2: Review Repository Structure

```bash
# View the structure
tree -L 2

# Key directories:
# .github/workflows/     - GitHub Actions workflows
# terraform/modules/     - Terraform modules
# terraform/backend/     - Backend configuration
# terraform/environments/ - Environment configs
# docs/guides/           - Usage guides
```

## OIDC Authentication Setup

**Why OIDC?** No need to store AWS credentials in GitHub! More secure and easier to manage.

### Step 1: Create OIDC Provider in AWS

```bash
# Get your GitHub organization/username
GITHUB_ORG="YOUR_GITHUB_USERNAME"  # Replace with your username

# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Verify creation
aws iam list-open-id-connect-providers
```

**Expected Output**:
```json
{
    "OpenIDConnectProviderList": [
        {
            "Arn": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
    ]
}
```

### Step 2: Create IAM Role for GitHub Actions

```bash
# Set variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
GITHUB_ORG="YOUR_GITHUB_USERNAME"  # Replace!
REPO_NAME="ramiz-takildar-infra"   # Replace if different!

# Create trust policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${REPO_NAME}:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json \
  --description "Role for GitHub Actions to deploy infrastructure"

# Attach admin policy (for initial setup)
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name GitHubActionsRole --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Save this ARN - you'll need it for GitHub secrets!
```

**⚠️ Security Note**: For production, replace `AdministratorAccess` with a custom policy with minimum required permissions.

### Step 3: Create Custom IAM Policy (Production)

For production environments, use least-privilege access:

```bash
# Create custom policy
cat > github-actions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "s3:*",
        "eks:*",
        "iam:*",
        "vpc:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "logs:*",
        "kms:*",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create policy
aws iam create-policy \
  --policy-name GitHubActionsPolicy \
  --policy-document file://github-actions-policy.json

# Attach to role (replace AdministratorAccess)
aws iam detach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/GitHubActionsPolicy
```

## Backend Configuration

Terraform needs a backend to store state files. We'll use S3 + DynamoDB for state storage and locking.

### Step 1: Create S3 Bucket for State

```bash
# Set variables
BUCKET_NAME="ramiz-takildar-infra"  # Must be globally unique!
REGION="us-east-1"

# Create S3 bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

# Enable versioning (important for state recovery)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable lifecycle policy (optional - clean up old versions)
cat > lifecycle.json <<EOF
{
  "Rules": [
    {
      "Id": "DeleteOldVersions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://lifecycle.json

echo "✅ S3 bucket created: $BUCKET_NAME"
```

### Step 2: Create DynamoDB Table for State Locking

```bash
# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

# Wait for table to be active
aws dynamodb wait table-exists --table-name terraform-locks

echo "✅ DynamoDB table created: terraform-locks"
```

### Step 3: Update Backend Configuration

```bash
# Navigate to backend directory
cd terraform/backend

# Update backend.hcl with your bucket name
cat > backend.hcl <<EOF
bucket         = "$BUCKET_NAME"
key            = "backend/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "terraform-locks"
encrypt        = true
EOF

echo "✅ Backend configuration updated"
```

### Step 4: Initialize Backend (Optional - for local testing)

```bash
# Initialize Terraform backend
terraform init -backend-config=backend.hcl

# Verify backend
terraform workspace list

echo "✅ Backend initialized"
```

## GitHub Secrets Configuration

### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

### Step 2: Add Required Secrets

Add these secrets one by one:

#### 1. AWS_ROLE_ARN (Required)
```
Name: AWS_ROLE_ARN
Value: arn:aws:iam::123456789012:role/GitHubActionsRole
```
(Use the Role ARN from OIDC setup)

#### 2. AWS_REGION (Optional)
```
Name: AWS_REGION
Value: us-east-1
```
(Default region for deployments)

### Step 3: Add Module-Specific Secrets

Depending on which modules you'll use, add these secrets:

#### For VPC Module
```
Name: VPC_ID
Value: vpc-0123456789abcdef0
```
(Add after creating your first VPC)

#### For EC2/EKS/RDS Modules
```
Name: SUBNET_IDS
Value: ["subnet-xxx", "subnet-yyy"]
```
(Add after creating VPC - JSON array format)

```
Name: PRIVATE_SUBNET_IDS
Value: ["subnet-xxx", "subnet-yyy"]
```
(Private subnets for databases/EKS)

#### For RDS Module
```
Name: DB_PASSWORD
Value: YourSecurePassword123!
```
(Strong password for database)

### Step 4: Verify Secrets

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. You should see all secrets listed
3. Secrets are encrypted and cannot be viewed after creation

**Minimum Required Secrets**:
- ✅ `AWS_ROLE_ARN`

**Optional but Recommended**:
- `AWS_REGION`
- `VPC_ID` (after VPC creation)
- `SUBNET_IDS` (after VPC creation)

## Verify Setup

### Step 1: Test AWS OIDC Authentication

Create a test workflow to verify OIDC works:

```bash
# Create test workflow
mkdir -p .github/workflows
cat > .github/workflows/test-setup.yml <<EOF
name: Test Setup

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: \${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Test AWS Access
        run: |
          echo "Testing AWS access..."
          aws sts get-caller-identity
          aws s3 ls
          echo "✅ AWS access verified!"
EOF

# Commit and push
git add .github/workflows/test-setup.yml
git commit -m "Add setup test workflow"
git push
```

### Step 2: Run Test Workflow

1. Go to **Actions** tab in GitHub
2. Select **"Test Setup"** workflow
3. Click **"Run workflow"**
4. Wait for completion (~30 seconds)

**Expected Output**:
```
✅ AWS access verified!
Account: 123456789012
UserId: AROAXXXXXXXXXXXXXXXXX:GitHubActions
Arn: arn:aws:sts::123456789012:assumed-role/GitHubActionsRole/GitHubActions
```

### Step 3: Verify Backend Access

```bash
# Test backend access locally
cd terraform/backend
terraform init -backend-config=backend.hcl

# Should see:
# Terraform has been successfully initialized!
```

### Step 4: Check Security Scanning

The workflows include security scanning with `tfsec` and `checkov`. Verify they work:

1. Make a small change to any Terraform file
2. Commit and push
3. Check that security scans run in GitHub Actions

## Deploy Your First Resource

Let's deploy a simple VPC to verify everything works!

### Step 1: Deploy VPC

1. Go to **Actions** → **VPC Infrastructure**
2. Click **"Run workflow"**
3. Configure:
   ```yaml
   Action: apply
   Environment: dev
   VPC Name: test-vpc
   VPC CIDR: 10.0.0.0/16
   Availability Zones: 2
   Create NAT Gateway: false  # Save costs for testing
   Enable VPC Flow Logs: false
   AWS Region: us-east-1
   ```
4. Click **"Run workflow"**
5. Wait for completion (~5 minutes)

### Step 2: Verify VPC Creation

```bash
# List VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=test-vpc" \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=test-vpc" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"
```

### Step 3: Add VPC ID to GitHub Secrets

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add new secret:
   ```
   Name: VPC_ID
   Value: vpc-0123456789abcdef0  # Your VPC ID
   ```

### Step 4: Get Subnet IDs

```bash
# Get subnet IDs
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Get public subnet IDs (for EC2)
PUBLIC_SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*public*" \
  --query 'Subnets[*].SubnetId' \
  --output json)

echo "Public Subnets: $PUBLIC_SUBNETS"

# Get private subnet IDs (for RDS/EKS)
PRIVATE_SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=*private*" \
  --query 'Subnets[*].SubnetId' \
  --output json)

echo "Private Subnets: $PRIVATE_SUBNETS"
```

### Step 5: Add Subnet IDs to GitHub Secrets

1. Add public subnets:
   ```
   Name: SUBNET_IDS
   Value: ["subnet-xxx", "subnet-yyy"]
   ```

2. Add private subnets:
   ```
   Name: PRIVATE_SUBNET_IDS
   Value: ["subnet-aaa", "subnet-bbb"]
   ```

### Step 6: Clean Up Test VPC (Optional)

If you want to clean up the test VPC:

1. Go to **Actions** → **VPC Infrastructure**
2. Click **"Run workflow"**
3. Configure:
   ```yaml
   Action: destroy
   Environment: dev
   VPC Name: test-vpc
   (same settings as creation)
   ```
4. Click **"Run workflow"**

## Troubleshooting

### Issue 1: OIDC Authentication Failed

**Error**: "Error: Could not assume role"

**Solutions**:

1. **Verify OIDC provider exists**:
```bash
aws iam list-open-id-connect-providers
```

2. **Check role trust policy**:
```bash
aws iam get-role --role-name GitHubActionsRole --query 'Role.AssumeRolePolicyDocument'
```

3. **Verify repository name in trust policy**:
```bash
# Trust policy should include:
# "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
```

4. **Check GitHub secret**:
- Go to Settings → Secrets
- Verify `AWS_ROLE_ARN` is correct

### Issue 2: Backend Initialization Failed

**Error**: "Error: Failed to get existing workspaces"

**Solutions**:

1. **Verify S3 bucket exists**:
```bash
aws s3 ls s3://ramiz-takildar-infra
```

2. **Check bucket permissions**:
```bash
aws s3api get-bucket-policy --bucket ramiz-takildar-infra
```

3. **Verify DynamoDB table**:
```bash
aws dynamodb describe-table --table-name terraform-locks
```

4. **Check IAM permissions**:
```bash
# Role needs s3:* and dynamodb:* permissions
aws iam list-attached-role-policies --role-name GitHubActionsRole
```

### Issue 3: Workflow Permission Denied

**Error**: "Error: User is not authorized to perform: ..."

**Solutions**:

1. **Check IAM role permissions**:
```bash
aws iam list-attached-role-policies --role-name GitHubActionsRole
```

2. **Add missing permissions**:
```bash
# Attach additional policy
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/SERVICE_POLICY
```

3. **Use AdministratorAccess temporarily**:
```bash
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Issue 4: Terraform State Lock

**Error**: "Error acquiring the state lock"

**Solutions**:

1. **Check DynamoDB table**:
```bash
aws dynamodb scan --table-name terraform-locks
```

2. **Force unlock** (if workflow was cancelled):
```bash
# Get lock ID from error message
terraform force-unlock LOCK_ID
```

3. **Delete stuck lock** (last resort):
```bash
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID": {"S": "LOCK_ID"}}'
```

### Issue 5: Security Scan Failures

**Error**: "tfsec found issues" or "checkov found issues"

**Solutions**:

1. **Review security findings**:
- Check workflow logs for details
- Each finding includes remediation steps

2. **Fix common issues**:
```hcl
# Enable encryption
enable_encryption = true

# Block public access
block_public_access = true

# Enable versioning
enable_versioning = true
```

3. **Suppress false positives** (use carefully):
```hcl
# Add comment above resource
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "example" {
  # ...
}
```

## Next Steps

Now that setup is complete, you can:

1. **Deploy Infrastructure**:
   - [VPC Usage Guide](VPC_USAGE_GUIDE.md)
   - [EC2 Usage Guide](EC2_USAGE_GUIDE.md)
   - [S3 Usage Guide](S3_USAGE_GUIDE.md)
   - [EKS Usage Guide](EKS_USAGE_GUIDE.md)
   - [RDS Usage Guide](RDS_USAGE_GUIDE.md)

2. **Customize Workflows**:
   - Modify `.github/workflows/` files
   - Add approval requirements
   - Configure notifications

3. **Set Up Environments**:
   - Create dev, staging, prod environments
   - Configure environment-specific secrets
   - Set up approval workflows

4. **Monitor Costs**:
   - Enable AWS Cost Explorer
   - Set up billing alerts
   - Review resource usage

## Quick Reference

### Essential Commands

```bash
# Get AWS account ID
aws sts get-caller-identity --query Account --output text

# List S3 buckets
aws s3 ls

# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table

# List EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Check Terraform state
aws s3 ls s3://ramiz-takildar-infra/ --recursive
```

### Important ARNs

```bash
# OIDC Provider
arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com

# GitHub Actions Role
arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole

# S3 Backend Bucket
arn:aws:s3:::ramiz-takildar-infra

# DynamoDB Lock Table
arn:aws:dynamodb:REGION:ACCOUNT_ID:table/terraform-locks
```

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check AWS CloudTrail for API errors
- Review module-specific usage guides

---

**Setup Complete!** 🎉

You're now ready to deploy AWS infrastructure using GitHub Actions!

**Last Updated**: May 2026