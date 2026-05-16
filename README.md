# AWS Infrastructure Provisioning Platform

> **Enterprise-grade self-service AWS infrastructure automation platform using Terraform, GitHub Actions, and OIDC authentication**

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Overview

This platform provides a **production-ready, self-service infrastructure provisioning system** that allows DevOps engineers to deploy and manage AWS resources directly from GitHub Actions using a simple UI-driven workflow.

### Key Features

- ✅ **Self-Service Deployment**: Provision infrastructure via GitHub Actions UI
- ✅ **OIDC Authentication**: Secure, keyless AWS authentication
- ✅ **Multi-Environment Support**: Dev, Staging, Production with approval gates
- ✅ **Reusable Terraform Modules**: Enterprise-grade, well-documented modules
- ✅ **Centralized State Management**: S3 backend with DynamoDB locking
- ✅ **Security Scanning**: Integrated tfsec and Checkov
- ✅ **Cost Optimization**: Built-in best practices and recommendations
- ✅ **Comprehensive Documentation**: Detailed guides and examples

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Supported Services](#-supported-services)
- [Prerequisites](#-prerequisites)
- [Setup Guide](#-setup-guide)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Terraform Modules](#-terraform-modules)
- [GitHub Actions Workflows](#-github-actions-workflows)
- [Backend Configuration](#-backend-configuration)
- [Security](#-security)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🚀 Quick Start

### 1. Setup AWS OIDC Provider

```bash
# Run the DynamoDB setup script
cd terraform/backend
chmod +x setup-dynamodb.sh
./setup-dynamodb.sh terraform-locks us-east-1
```

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

- `AWS_ROLE_ARN`: ARN of the IAM role for OIDC authentication

### 3. Deploy Infrastructure

1. Go to **Actions** tab in GitHub
2. Select a workflow (e.g., "EC2 Infrastructure")
3. Click **Run workflow**
4. Fill in the parameters
5. Click **Run workflow**

That's it! Your infrastructure will be provisioned automatically.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Actions                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ EC2 Workflow │  │ S3 Workflow  │  │ VPC Workflow │  ...    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────────────┴──────────────────┘                 │
│                            │                                     │
│                    ┌───────▼────────┐                           │
│                    │  OIDC Provider │                           │
│                    └───────┬────────┘                           │
└────────────────────────────┼──────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   AWS Account   │
                    │                 │
                    │  ┌───────────┐  │
                    │  │ IAM Role  │  │
                    │  └─────┬─────┘  │
                    │        │        │
                    │  ┌─────▼─────┐  │
                    │  │ Terraform │  │
                    │  │  Backend  │  │
                    │  │           │  │
                    │  │ S3 Bucket │  │
                    │  │ DynamoDB  │  │
                    │  └─────┬─────┘  │
                    │        │        │
                    │  ┌─────▼─────┐  │
                    │  │   AWS     │  │
                    │  │ Resources │  │
                    │  │           │  │
                    │  │ EC2, S3,  │  │
                    │  │ VPC, EKS  │  │
                    │  └───────────┘  │
                    └─────────────────┘
```

### State Management Architecture

```
S3 Bucket: ramiz-takildar-infra (us-east-1)
├── dev/
│   ├── ec2/terraform.tfstate
│   ├── s3/terraform.tfstate
│   ├── vpc/terraform.tfstate
│   └── eks/terraform.tfstate
├── staging/
│   ├── ec2/terraform.tfstate
│   ├── s3/terraform.tfstate
│   └── vpc/terraform.tfstate
└── prod/
    ├── ec2/terraform.tfstate
    ├── s3/terraform.tfstate
    └── vpc/terraform.tfstate

DynamoDB Table: terraform-locks
├── LockID (Hash Key)
└── State locking for concurrent operations
```

## 🛠️ Supported Services

| Service | Status | Workflow | Module |
|---------|--------|----------|--------|
| **EC2 Instances** | ✅ Ready | [ec2-infrastructure.yml](.github/workflows/ec2-infrastructure.yml) | [ec2](terraform/modules/ec2/) |
| **S3 Buckets** | ✅ Ready | [s3-infrastructure.yml](.github/workflows/s3-infrastructure.yml) | [s3](terraform/modules/s3/) |
| **VPC** | ✅ Ready | [vpc-infrastructure.yml](.github/workflows/vpc-infrastructure.yml) | [vpc](terraform/modules/vpc/) |
| **EKS Cluster** | ✅ Ready | [eks-infrastructure.yml](.github/workflows/eks-infrastructure.yml) | [eks](terraform/modules/eks/) |
| **RDS Database** | ✅ Ready | [rds-infrastructure.yml](.github/workflows/rds-infrastructure.yml) | [rds](terraform/modules/rds/) |
| **Lambda** | 📋 Planned | - | - |
| **ALB** | 📋 Planned | - | - |
| **Auto Scaling** | 📋 Planned | - | - |
| **CloudWatch** | 📋 Planned | - | - |
| **IAM Roles** | 📋 Planned | - | - |
| **Security Groups** | 📋 Planned | - | - |

## 📦 Prerequisites

### Required Tools

- **Terraform**: >= 1.5.0
- **AWS CLI**: >= 2.0
- **Git**: >= 2.0
- **GitHub Account**: With Actions enabled

### AWS Requirements

- AWS Account with appropriate permissions
- IAM OIDC Identity Provider configured
- IAM Role for GitHub Actions
- S3 bucket for Terraform state (already exists: `ramiz-takildar-infra`)

### GitHub Requirements

- Repository with Actions enabled
- GitHub Environments configured (dev, staging, prod)
- Required secrets configured

## 🔧 Setup Guide

### Step 1: Configure AWS OIDC Provider

Create an OIDC Identity Provider in AWS:

```bash
# Using AWS CLI
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Create IAM Role

Create an IAM role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

Attach necessary permissions policies:
- `AmazonEC2FullAccess`
- `AmazonS3FullAccess`
- `AmazonVPCFullAccess`
- Custom policy for Terraform state management

### Step 3: Setup DynamoDB Lock Table

```bash
cd terraform/backend
./setup-dynamodb.sh terraform-locks us-east-1
```

### Step 4: Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ROLE_ARN` | IAM Role ARN for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `KMS_KEY_ID` | (Optional) KMS key for encryption | `arn:aws:kms:us-east-1:123456789012:key/...` |
| `LOGGING_BUCKET` | (Optional) S3 bucket for logs | `my-logs-bucket` |

### Step 5: Configure GitHub Environments

Create the following environments with protection rules:

#### Development Environment
- **Name**: `dev`
- **Protection Rules**: None (auto-deploy)

#### Staging Environment
- **Name**: `staging`
- **Protection Rules**: Optional approval

#### Production Environment
- **Name**: `prod`
- **Protection Rules**: 
  - Required reviewers (2+)
  - Deployment branches: `main` only

#### Destroy Environments
- **Name**: `dev-destroy`, `staging-destroy`, `prod-destroy`
- **Protection Rules**: Required approval for all

## 📖 Usage

### Deploying EC2 Instances

1. Navigate to **Actions** → **EC2 Infrastructure**
2. Click **Run workflow**
3. Configure parameters:
   - **Action**: `apply`
   - **Environment**: `dev`
   - **Instance Name**: `web-server`
   - **Instance Type**: `t3.micro`
   - **Instance Count**: `2`
   - **AMI OS**: `ubuntu-22.04`
   - **AWS Region**: `us-east-1`
4. Click **Run workflow**

### Creating S3 Buckets

1. Navigate to **Actions** → **S3 Infrastructure**
2. Click **Run workflow**
3. Configure parameters:
   - **Action**: `apply`
   - **Environment**: `prod`
   - **Bucket Name**: `my-app-data`
   - **Enable Versioning**: `true`
   - **Enable Encryption**: `true`
   - **Block Public Access**: `true`
4. Click **Run workflow**

### Provisioning VPC

1. Navigate to **Actions** → **VPC Infrastructure**
2. Click **Run workflow**
3. Configure parameters:
   - **Action**: `apply`
   - **Environment**: `prod`
   - **VPC Name**: `production-vpc`
   - **VPC CIDR**: `10.0.0.0/16`
   - **Availability Zones**: `3`
   - **Create NAT Gateway**: `true`
4. Click **Run workflow**

## 📁 Project Structure

```
ramiz-takildar-infra/
├── .github/
│   ├── actions/                    # Reusable composite actions
│   │   ├── aws-oidc/              # AWS OIDC authentication
│   │   ├── setup-terraform/       # Terraform setup
│   │   ├── terraform-plan/        # Terraform plan
│   │   ├── terraform-apply/       # Terraform apply
│   │   └── terraform-destroy/     # Terraform destroy
│   └── workflows/                  # GitHub Actions workflows
│       ├── ec2-infrastructure.yml
│       ├── s3-infrastructure.yml
│       ├── vpc-infrastructure.yml
│       └── drift-detection.yml
├── terraform/
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── ec2/                   # EC2 instance module
│   │   ├── s3/                    # S3 bucket module
│   │   ├── vpc/                   # VPC module
│   │   ├── eks/                   # EKS cluster module
│   │   ├── rds/                   # RDS database module
│   │   └── ...
│   ├── environments/               # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── backend/                    # Backend configuration
│   │   ├── backend.tf
│   │   ├── backend.hcl
│   │   ├── providers.tf
│   │   └── setup-dynamodb.sh
│   └── scripts/                    # Helper scripts
├── docs/                           # Documentation
│   ├── architecture/
│   ├── guides/
│   └── examples/
├── scripts/                        # Utility scripts
├── Makefile                        # Common tasks
└── README.md                       # This file
```

## 🧩 Terraform Modules

### EC2 Module

Provisions EC2 instances with enterprise features:

```hcl
module "ec2" {
  source = "../../modules/ec2"

  instance_name  = "web-server"
  instance_type  = "t3.micro"
  instance_count = 2
  subnet_ids     = ["subnet-xxx", "subnet-yyy"]
  
  tags = {
    Environment = "production"
  }
}
```

**Features**:
- Multi-instance support
- Custom AMI selection
- Security group management
- IAM instance profiles
- EBS volume configuration
- CloudWatch monitoring

[📚 Full Documentation](terraform/modules/ec2/README.md)

### S3 Module

Creates S3 buckets with security best practices:

```hcl
module "s3" {
  source = "../../modules/s3"

  bucket_name       = "my-app-data"
  enable_versioning = true
  enable_encryption = true
  
  lifecycle_rules = [
    {
      id      = "archive-old-data"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]
}
```

**Features**:
- Versioning and encryption
- Lifecycle policies
- Access logging
- CORS configuration
- Replication support
- Object lock

[📚 Full Documentation](terraform/modules/s3/README.md)

### VPC Module

Deploys complete VPC infrastructure:

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "production-vpc"
  vpc_cidr = "10.0.0.0/16"
  
  max_availability_zones = 3
  create_nat_gateway     = true
  enable_flow_logs       = true
}
```

**Features**:
- Multi-AZ deployment
- Public/private/database subnets
- NAT Gateways
- VPC Flow Logs
- VPC Endpoints
- Route tables

[📚 Full Documentation](terraform/modules/vpc/README.md)

### EKS Module

Deploys production-ready Kubernetes clusters:

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "production-eks"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  node_groups = {
    general = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  
  enable_irsa = true
}
```

**Features**:
- Managed node groups
- Fargate profiles
- OIDC provider for IRSA
- Cluster add-ons (VPC CNI, CoreDNS, kube-proxy)
- Multi-AZ deployment
- CloudWatch logging
- KMS encryption

[📚 Full Documentation](terraform/modules/eks/README.md)

### RDS Module

Creates managed database instances:

```hcl
module "rds" {
  source = "../../modules/rds"

  identifier     = "production-db"
  engine         = "postgres"
  engine_version = "15.3"
  instance_class = "db.r6g.large"
  
  allocated_storage = 100
  storage_encrypted = true
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids
  
  multi_az = true
  
  backup_retention_period = 30
  performance_insights_enabled = true
}
```

**Features**:
- Multiple database engines (PostgreSQL, MySQL, MariaDB, Oracle, SQL Server)
- Multi-AZ deployment
- Read replicas
- Automated backups
- Performance Insights
- Enhanced monitoring
- Secrets Manager integration
- CloudWatch alarms

[📚 Full Documentation](terraform/modules/rds/README.md)

## ⚙️ GitHub Actions Workflows

### Composite Actions

Reusable actions for common tasks:

| Action | Purpose | Usage |
|--------|---------|-------|
| `aws-oidc` | AWS authentication via OIDC | [action.yml](.github/actions/aws-oidc/action.yml) |
| `setup-terraform` | Setup Terraform with caching | [action.yml](.github/actions/setup-terraform/action.yml) |
| `terraform-plan` | Run terraform plan | [action.yml](.github/actions/terraform-plan/action.yml) |
| `terraform-apply` | Run terraform apply | [action.yml](.github/actions/terraform-apply/action.yml) |
| `terraform-destroy` | Run terraform destroy | [action.yml](.github/actions/terraform-destroy/action.yml) |

### Service Workflows

| Workflow | Description | Trigger |
|----------|-------------|---------|
| EC2 Infrastructure | Provision EC2 instances | Manual (workflow_dispatch) |
| S3 Infrastructure | Create S3 buckets | Manual (workflow_dispatch) |
| VPC Infrastructure | Deploy VPC | Manual (workflow_dispatch) |
| Drift Detection | Detect configuration drift | Scheduled (daily) |

## 🗄️ Backend Configuration

### Centralized State Management

All Terraform state is stored in a centralized S3 bucket:

- **Bucket**: `ramiz-takildar-infra`
- **Region**: `us-east-1`
- **Encryption**: Enabled (AES256)
- **Versioning**: Enabled
- **Locking**: DynamoDB table `terraform-locks`

### State File Organization

```
Environment/Service/terraform.tfstate

Examples:
- dev/ec2/terraform.tfstate
- dev/s3/terraform.tfstate
- staging/vpc/terraform.tfstate
- prod/eks/terraform.tfstate
```

### Benefits

1. **Isolation**: Each service has its own state file
2. **Parallel Execution**: Multiple teams can work simultaneously
3. **Blast Radius Reduction**: Errors are contained
4. **Easy Rollbacks**: Revert specific services independently

[📚 Backend Documentation](terraform/backend/README.md)

## 🔒 Security

### OIDC Authentication

- **No long-lived credentials** stored in GitHub
- **Automatic credential rotation**
- **Fine-grained IAM permissions**
- **Audit trail** via CloudTrail

### Security Scanning

Every workflow includes:

- **tfsec**: Terraform security scanner
- **Checkov**: Infrastructure as Code scanner
- **SARIF upload**: Results uploaded to GitHub Security

### Best Practices

1. ✅ All resources encrypted at rest
2. ✅ Public access blocked by default
3. ✅ Least privilege IAM policies
4. ✅ VPC Flow Logs enabled
5. ✅ CloudWatch monitoring
6. ✅ Approval gates for production
7. ✅ State file encryption
8. ✅ MFA for sensitive operations

## 📊 Best Practices

### Cost Optimization

1. **Use appropriate instance types**
2. **Enable S3 Intelligent-Tiering**
3. **Single NAT Gateway for dev/test**
4. **Use VPC Endpoints** to reduce data transfer
5. **Implement lifecycle policies**
6. **Monitor with AWS Cost Explorer**

### High Availability

1. **Multi-AZ deployments**
2. **Auto Scaling Groups**
3. **Load Balancers**
4. **Database replication**
5. **Regular backups**

### Disaster Recovery

1. **Cross-region replication**
2. **Automated backups**
3. **State file versioning**
4. **Documented recovery procedures**
5. **Regular DR testing**

## 🐛 Troubleshooting

### Common Issues

#### OIDC Authentication Fails

**Problem**: `Error: Unable to assume role`

**Solution**:
1. Verify IAM role trust policy
2. Check GitHub repository name in trust policy
3. Ensure OIDC provider is configured
4. Verify `id-token: write` permission in workflow

#### State Lock Timeout

**Problem**: `Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### Terraform Init Fails

**Problem**: `Error: Failed to get existing workspaces`

**Solution**:
1. Verify S3 bucket exists
2. Check IAM permissions
3. Ensure DynamoDB table exists
4. Verify backend configuration

### Getting Help

1. Check [GitHub Issues](https://github.com/ramiz-takildar/ramiz-takildar-infra/issues)
2. Review workflow logs
3. Check AWS CloudTrail
4. Contact DevOps team

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

### Development Workflow

```bash
# Clone repository
git clone https://github.com/ramiz-takildar/ramiz-takildar-infra.git
cd ramiz-takildar-infra

# Create feature branch
git checkout -b feature/new-module

# Make changes
# ...

# Test locally
cd terraform/modules/new-module
terraform init
terraform validate
terraform plan

# Commit and push
git add .
git commit -m "Add new module"
git push origin feature/new-module
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **DevOps Team** - Initial work and maintenance

## 🙏 Acknowledgments

- HashiCorp for Terraform
- AWS for cloud infrastructure
- GitHub for Actions platform
- Open source community

## 📞 Support

For support and questions:

- **Email**: devops@example.com
- **Slack**: #infrastructure-platform
- **Issues**: [GitHub Issues](https://github.com/ramiz-takildar/ramiz-takildar-infra/issues)

---

**Built with ❤️ by the DevOps Team**

*Last Updated: May 2026*
