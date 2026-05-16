# VPC Module Usage Guide

> **Complete guide for deploying and managing Amazon VPC (Virtual Private Cloud) using the Infrastructure Provisioning Platform**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Options](#configuration-options)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [Common Use Cases](#common-use-cases)
8. [VPC Management](#vpc-management)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The VPC module provisions Amazon Virtual Private Cloud with enterprise features:

- **Network Isolation**: Logically isolated network in AWS
- **Subnets**: Public and private subnets across multiple AZs
- **Internet Gateway**: Internet connectivity for public subnets
- **NAT Gateway**: Outbound internet for private subnets
- **Route Tables**: Custom routing for traffic control
- **Network ACLs**: Stateless firewall at subnet level
- **VPC Flow Logs**: Network traffic monitoring
- **VPC Endpoints**: Private AWS service access
- **DNS Support**: Custom DNS resolution

## Prerequisites

### 1. AWS Resources Required

Before deploying VPC, ensure you have:

- ✅ **AWS OIDC Provider**: Configured for GitHub Actions
- ✅ **IAM Role**: With VPC permissions for GitHub Actions
- ✅ **Available IP Space**: Plan CIDR blocks carefully
- ✅ **S3 Bucket** (Optional): For VPC Flow Logs

### 2. GitHub Secrets Required

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |

### 3. CIDR Planning

**Important Considerations**:
- Choose non-overlapping CIDR blocks
- Plan for future growth
- Consider VPC peering requirements
- Avoid conflicts with on-premises networks

**Common CIDR Blocks**:
- Small: `10.0.0.0/24` (256 IPs)
- Medium: `10.0.0.0/20` (4,096 IPs)
- Large: `10.0.0.0/16` (65,536 IPs)
- Extra Large: `10.0.0.0/8` (16,777,216 IPs)

## Quick Start

### 5-Minute Deployment

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → VPC Infrastructure
   ```

2. **Click "Run workflow"**

3. **Use these settings**:
   ```yaml
   Action: apply
   Environment: dev
   VPC Name: app-vpc
   VPC CIDR: 10.0.0.0/16
   Availability Zones: 2
   Create NAT Gateway: true
   Enable VPC Flow Logs: true
   AWS Region: us-east-1
   ```

4. **Click "Run workflow"** and wait (~5-8 minutes)

5. **Verify deployment**:
   ```bash
   # Get VPC ID from workflow output
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=app-vpc"
   ```

## Step-by-Step Deployment

### Step 1: Access GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **"VPC Infrastructure"** from the workflows list

### Step 2: Start Workflow

1. Click the **"Run workflow"** button
2. A form will appear with deployment options

### Step 3: Configure Basic Settings

#### Action Selection
```
Action: apply
```
- **plan**: Preview changes
- **apply**: Create/update VPC
- **destroy**: Delete VPC (must be empty)

#### Environment Selection
```
Environment: dev
```
- **dev**: Development (no approval)
- **staging**: Staging (optional approval)
- **prod**: Production (requires approval)

#### VPC Name
```
VPC Name: app-vpc
```

**Naming Best Practices**:
- Include environment: `app-vpc-prod`
- Include purpose: `web-vpc`, `data-vpc`
- Use organization prefix: `acme-app-vpc`

**Examples**:
- ✅ `app-vpc-prod`
- ✅ `web-services-vpc`
- ✅ `data-platform-vpc-staging`

### Step 4: Configure Network

#### VPC CIDR Block
```
VPC CIDR: 10.0.0.0/16
```

**CIDR Selection Guide**:

| CIDR Block | Total IPs | Usable IPs | Use Case |
|------------|-----------|------------|----------|
| `/28` | 16 | 11 | Very small (testing) |
| `/24` | 256 | 251 | Small (dev/test) |
| `/20` | 4,096 | 4,091 | Medium (staging) |
| `/16` | 65,536 | 65,531 | Large (production) |
| `/8` | 16,777,216 | 16,777,211 | Enterprise |

**Recommendations**:
- **Dev**: `/24` or `/20`
- **Staging**: `/20` or `/16`
- **Production**: `/16` or larger

**Private IP Ranges** (RFC 1918):
- `10.0.0.0/8` (10.0.0.0 - 10.255.255.255)
- `172.16.0.0/12` (172.16.0.0 - 172.31.255.255)
- `192.168.0.0/16` (192.168.0.0 - 192.168.255.255)

#### Availability Zones
```
Availability Zones: 2
```

**Guidelines**:
- **Dev**: 1-2 AZs
- **Staging**: 2 AZs
- **Production**: 3+ AZs

**Benefits of Multiple AZs**:
- High availability
- Fault tolerance
- Disaster recovery
- Load distribution

### Step 5: Configure NAT Gateway

```
Create NAT Gateway: true
```

**NAT Gateway Options**:
- **true**: Create NAT Gateway (recommended)
- **false**: No outbound internet for private subnets

**When to Enable**:
- ✅ Private instances need internet access
- ✅ Software updates required
- ✅ External API calls needed
- ❌ Fully isolated environment
- ❌ Cost-sensitive dev environment

**Cost Considerations**:
- NAT Gateway: ~$32/month per AZ
- Data processing: $0.045/GB
- Alternative: NAT Instance (cheaper but less reliable)

### Step 6: Configure VPC Flow Logs

```
Enable VPC Flow Logs: true
```

**Benefits**:
- Network traffic monitoring
- Security analysis
- Troubleshooting connectivity
- Compliance requirements

**Storage Options**:
- CloudWatch Logs (default)
- S3 bucket (cheaper for long-term)

**Cost**:
- CloudWatch: ~$0.50/GB ingested
- S3: ~$0.023/GB/month

### Step 7: Select AWS Region

```
AWS Region: us-east-1
```

**Region Selection Factors**:
- Latency to users
- Service availability
- Compliance requirements
- Cost differences

**Popular Regions**:
- `us-east-1`: N. Virginia (most services)
- `us-west-2`: Oregon
- `eu-west-1`: Ireland
- `ap-southeast-1`: Singapore

### Step 8: Review and Deploy

1. **Review all settings**
2. **Click "Run workflow"**
3. **Monitor progress**

**Deployment Timeline**:
- Security Scan: 2-3 minutes
- Terraform Plan: 2-3 minutes
- Approval (if prod): Variable
- Terraform Apply: 3-5 minutes
- **Total**: ~5-15 minutes

### Step 9: Verify Deployment

Check the **deployment summary**:

```
✅ VPC Deployed Successfully!

VPC Details:
- VPC Name: app-vpc
- Environment: dev
- VPC CIDR: 10.0.0.0/16
- Availability Zones: 2
- NAT Gateway: Enabled
- Flow Logs: Enabled
- Region: us-east-1

VPC ID: vpc-0123456789abcdef0

Subnets:
Public Subnets:
- subnet-0123456789abcdef0 (10.0.1.0/24, us-east-1a)
- subnet-0123456789abcdef1 (10.0.2.0/24, us-east-1b)

Private Subnets:
- subnet-0123456789abcdef2 (10.0.11.0/24, us-east-1a)
- subnet-0123456789abcdef3 (10.0.12.0/24, us-east-1b)

Internet Gateway: igw-0123456789abcdef0
NAT Gateways:
- nat-0123456789abcdef0 (us-east-1a)
- nat-0123456789abcdef1 (us-east-1b)
```

## Configuration Options

### Basic Configuration

```hcl
# Minimum required
vpc_name = "app-vpc"
vpc_cidr = "10.0.0.0/16"

# Availability zones
availability_zones = 2

# NAT Gateway
create_nat_gateway = true

# Flow Logs
enable_flow_logs = true
```

### Production Configuration

```hcl
# Production-ready VPC
vpc_name = "prod-app-vpc"
vpc_cidr = "10.0.0.0/16"

# High Availability
availability_zones = 3

# Subnets
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# NAT Gateway (one per AZ for HA)
create_nat_gateway = true
single_nat_gateway = false
one_nat_gateway_per_az = true

# DNS
enable_dns_hostnames = true
enable_dns_support   = true

# Flow Logs
enable_flow_logs = true
flow_logs_destination_type = "s3"
flow_logs_s3_bucket = "prod-vpc-flow-logs"
flow_logs_retention_days = 90

# VPC Endpoints (save NAT costs)
enable_s3_endpoint = true
enable_dynamodb_endpoint = true

# Private endpoints for AWS services
vpc_endpoints = {
  ec2 = {
    service = "ec2"
    private_dns_enabled = true
  }
  ecr_api = {
    service = "ecr.api"
    private_dns_enabled = true
  }
  ecr_dkr = {
    service = "ecr.dkr"
    private_dns_enabled = true
  }
  logs = {
    service = "logs"
    private_dns_enabled = true
  }
}

# Network ACLs
enable_network_acls = true

# Tags
tags = {
  Environment = "production"
  Application = "myapp"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
```

### Multi-Tier Architecture

```hcl
# Three-tier architecture
vpc_name = "three-tier-vpc"
vpc_cidr = "10.0.0.0/16"

availability_zones = 3

# Web tier (public)
public_subnet_cidrs = [
  "10.0.1.0/24",   # us-east-1a
  "10.0.2.0/24",   # us-east-1b
  "10.0.3.0/24"    # us-east-1c
]

# Application tier (private)
private_subnet_cidrs = [
  "10.0.11.0/24",  # us-east-1a
  "10.0.12.0/24",  # us-east-1b
  "10.0.13.0/24"   # us-east-1c
]

# Database tier (private)
database_subnet_cidrs = [
  "10.0.21.0/24",  # us-east-1a
  "10.0.22.0/24",  # us-east-1b
  "10.0.23.0/24"   # us-east-1c
]

# NAT Gateway for private subnets
create_nat_gateway = true
one_nat_gateway_per_az = true
```

## Post-Deployment Setup

### 1. Verify VPC Configuration

```bash
# Get VPC details
VPC_ID="vpc-0123456789abcdef0"

aws ec2 describe-vpcs --vpc-ids $VPC_ID

# List subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# List route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"

# List internet gateways
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID"

# List NAT gateways
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID"
```

### 2. Test Connectivity

#### Test Public Subnet
```bash
# Launch test instance in public subnet
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id subnet-public \
  --associate-public-ip-address \
  --key-name my-key

# SSH to instance
ssh -i my-key.pem ec2-user@<public-ip>

# Test internet connectivity
ping -c 4 8.8.8.8
curl https://www.google.com
```

#### Test Private Subnet
```bash
# Launch test instance in private subnet
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.micro \
  --subnet-id subnet-private \
  --no-associate-public-ip-address \
  --key-name my-key

# SSH via bastion host
ssh -i my-key.pem -J ec2-user@<bastion-ip> ec2-user@<private-ip>

# Test outbound internet (via NAT)
ping -c 4 8.8.8.8
curl https://www.google.com
```

### 3. Configure Security Groups

```bash
# Create security group for web servers
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Security group for web servers" \
  --vpc-id $VPC_ID

# Allow HTTP/HTTPS
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Create security group for application servers
aws ec2 create-security-group \
  --group-name app-sg \
  --description "Security group for app servers" \
  --vpc-id $VPC_ID

# Allow traffic from web tier
aws ec2 authorize-security-group-ingress \
  --group-id sg-app \
  --protocol tcp \
  --port 8080 \
  --source-group sg-web

# Create security group for database
aws ec2 create-security-group \
  --group-name db-sg \
  --description "Security group for database" \
  --vpc-id $VPC_ID

# Allow traffic from app tier
aws ec2 authorize-security-group-ingress \
  --group-id sg-db \
  --protocol tcp \
  --port 5432 \
  --source-group sg-app
```

### 4. Set Up VPC Peering (Optional)

```bash
# Create peering connection
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-requester \
  --peer-vpc-id vpc-accepter \
  --peer-region us-east-1

# Accept peering connection
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-xxx

# Update route tables
aws ec2 create-route \
  --route-table-id rtb-xxx \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-xxx
```

### 5. Configure VPC Endpoints

```bash
# Create S3 endpoint (gateway)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx

# Create interface endpoint (e.g., ECR)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --vpc-endpoint-type Interface \
  --service-name com.amazonaws.us-east-1.ecr.api \
  --subnet-ids subnet-xxx subnet-yyy \
  --security-group-ids sg-xxx
```

## Common Use Cases

### Use Case 1: Simple Web Application

**Requirements**: Host web application with database

```yaml
# Via GitHub Actions
Action: apply
Environment: prod
VPC Name: webapp-vpc
VPC CIDR: 10.0.0.0/16
Availability Zones: 2
Create NAT Gateway: true
Enable VPC Flow Logs: true
```

**Architecture**:
```
Internet
    ↓
Internet Gateway
    ↓
Public Subnets (10.0.1.0/24, 10.0.2.0/24)
    ↓ (Load Balancer)
Private Subnets (10.0.11.0/24, 10.0.12.0/24)
    ↓ (Application Servers)
Database Subnets (10.0.21.0/24, 10.0.22.0/24)
    ↓ (RDS)
```

**Cost**: ~$70/month (2 NAT Gateways)

### Use Case 2: Microservices Platform

**Requirements**: Multiple services, service mesh, container orchestration

```yaml
Action: apply
Environment: prod
VPC Name: microservices-vpc
VPC CIDR: 10.0.0.0/16
Availability Zones: 3
Create NAT Gateway: true
Enable VPC Flow Logs: true
```

**Additional Configuration**:
```hcl
# EKS-optimized subnets
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]

# VPC endpoints for cost savings
enable_s3_endpoint = true
enable_dynamodb_endpoint = true

vpc_endpoints = {
  ecr_api = { service = "ecr.api" }
  ecr_dkr = { service = "ecr.dkr" }
  ec2 = { service = "ec2" }
  logs = { service = "logs" }
}
```

**Cost**: ~$105/month (3 NAT Gateways)

### Use Case 3: Hybrid Cloud

**Requirements**: Connect to on-premises data center

```yaml
Action: apply
Environment: prod
VPC Name: hybrid-vpc
VPC CIDR: 10.10.0.0/16  # Non-overlapping with on-prem
Availability Zones: 2
Create NAT Gateway: true
Enable VPC Flow Logs: true
```

**Additional Setup**:
```bash
# Create Virtual Private Gateway
aws ec2 create-vpn-gateway --type ipsec.1

# Attach to VPC
aws ec2 attach-vpn-gateway \
  --vpn-gateway-id vgw-xxx \
  --vpc-id $VPC_ID

# Create Customer Gateway
aws ec2 create-customer-gateway \
  --type ipsec.1 \
  --public-ip <on-prem-ip> \
  --bgp-asn 65000

# Create VPN Connection
aws ec2 create-vpn-connection \
  --type ipsec.1 \
  --customer-gateway-id cgw-xxx \
  --vpn-gateway-id vgw-xxx
```

**Cost**: ~$70/month (NAT) + $36/month (VPN)

### Use Case 4: Multi-Account Setup

**Requirements**: Separate VPCs for different environments/teams

```yaml
# Development Account
Action: apply
Environment: dev
VPC Name: dev-vpc
VPC CIDR: 10.0.0.0/16
Availability Zones: 2
Create NAT Gateway: false  # Cost savings

# Staging Account
Action: apply
Environment: staging
VPC Name: staging-vpc
VPC CIDR: 10.1.0.0/16
Availability Zones: 2
Create NAT Gateway: true

# Production Account
Action: apply
Environment: prod
VPC Name: prod-vpc
VPC CIDR: 10.2.0.0/16
Availability Zones: 3
Create NAT Gateway: true
```

**Transit Gateway** (for inter-VPC communication):
```bash
# Create Transit Gateway
aws ec2 create-transit-gateway \
  --description "Multi-account TGW"

# Attach VPCs
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxx \
  --vpc-id vpc-dev

aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxx \
  --vpc-id vpc-staging

aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-xxx \
  --vpc-id vpc-prod
```

## VPC Management

### Monitor VPC Flow Logs

```bash
# Query flow logs (CloudWatch Logs Insights)
aws logs start-query \
  --log-group-name "/aws/vpc/flowlogs" \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, protocol, bytes
| filter action = "REJECT"
| sort @timestamp desc
| limit 100'

# Download flow logs from S3
aws s3 sync s3://vpc-flow-logs-bucket/AWSLogs/ ./flow-logs/

# Analyze with Athena
CREATE EXTERNAL TABLE vpc_flow_logs (
  version int,
  account string,
  interfaceid string,
  sourceaddress string,
  destinationaddress string,
  sourceport int,
  destinationport int,
  protocol int,
  numpackets int,
  numbytes bigint,
  starttime int,
  endtime int,
  action string,
  logstatus string
)
PARTITIONED BY (dt string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION 's3://vpc-flow-logs-bucket/AWSLogs/'
TBLPROPERTIES ("skip.header.line.count"="1");
```

### Modify VPC

```bash
# Modify VPC attributes
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support

# Add secondary CIDR block
aws ec2 associate-vpc-cidr-block \
  --vpc-id $VPC_ID \
  --cidr-block 10.1.0.0/16
```

### Add Subnets

```bash
# Create new subnet
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1c

# Associate with route table
aws ec2 associate-route-table \
  --subnet-id subnet-xxx \
  --route-table-id rtb-xxx
```

### Update Route Tables

```bash
# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id rtb-xxx \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-xxx

# Add route to VPC peering
aws ec2 create-route \
  --route-table-id rtb-xxx \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-xxx

# Delete route
aws ec2 delete-route \
  --route-table-id rtb-xxx \
  --destination-cidr-block 0.0.0.0/0
```

### Network ACLs

```bash
# Create network ACL
aws ec2 create-network-acl --vpc-id $VPC_ID

# Add inbound rule
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxx \
  --ingress \
  --rule-number 100 \
  --protocol tcp \
  --port-range From=80,To=80 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

# Add outbound rule
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxx \
  --egress \
  --rule-number 100 \
  --protocol -1 \
  --cidr-block 0.0.0.0/0 \
  --rule-action allow

# Associate with subnet
aws ec2 replace-network-acl-association \
  --association-id aclassoc-xxx \
  --network-acl-id acl-xxx
```

## Troubleshooting

### Issue 1: Cannot Connect to Internet from Private Subnet

**Symptoms**:
```bash
# From private instance
ping 8.8.8.8
# Request timeout
```

**Diagnosis**:
```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID"

# Check route table
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"

# Check network ACLs
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID"
```

**Solutions**:

1. **Verify NAT Gateway exists and is available**:
```bash
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].[NatGatewayId,State]'
```

2. **Check route table has route to NAT Gateway**:
```bash
# Should have route: 0.0.0.0/0 → nat-xxx
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].Routes'
```

3. **Verify subnet association**:
```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].[RouteTableId,Associations[*].SubnetId]'
```

4. **Check security groups**:
```bash
# Ensure outbound rules allow traffic
aws ec2 describe-security-groups --group-ids sg-xxx
```

### Issue 2: Cannot Access Resources in VPC

**Symptoms**:
Cannot SSH to instances, cannot access databases

**Diagnosis**:
```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID"

# Check network ACLs
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"
```

**Solutions**:

1. **Verify security group rules**:
```bash
# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32
```

2. **Check network ACL rules**:
```bash
# Network ACLs are stateless, need both inbound and outbound
aws ec2 describe-network-acls --network-acl-ids acl-xxx
```

3. **Verify route table**:
```bash
# Ensure proper routing
aws ec2 describe-route-tables --route-table-ids rtb-xxx
```

### Issue 3: VPC Peering Not Working

**Symptoms**:
Cannot communicate between peered VPCs

**Diagnosis**:
```bash
# Check peering connection status
aws ec2 describe-vpc-peering-connections \
  --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID"

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"
```

**Solutions**:

1. **Verify peering connection is active**:
```bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids pcx-xxx \
  --query 'VpcPeeringConnections[*].Status'
```

2. **Add routes in both VPCs**:
```bash
# In VPC A
aws ec2 create-route \
  --route-table-id rtb-vpc-a \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-xxx

# In VPC B
aws ec2 create-route \
  --route-table-id rtb-vpc-b \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id pcx-xxx
```

3. **Update security groups**:
```bash
# Allow traffic from peered VPC CIDR
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol -1 \
  --cidr 10.1.0.0/16
```

### Issue 4: High NAT Gateway Costs

**Diagnosis**:
```bash
# Check NAT Gateway data processing
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToDestination \
  --dimensions Name=NatGatewayId,Value=nat-xxx \
  --start-time 2026-05-01T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 86400 \
  --statistics Sum
```

**Solutions**:

1. **Use VPC Endpoints**:
```bash
# Create S3 endpoint (free)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx

# Create DynamoDB endpoint (free)
aws ec2 create-vpc-endpoint \
  --vpc-id $VPC_ID \
  --service-name com.amazonaws.us-east-1.dynamodb \
  --route-table-ids rtb-xxx
```

2. **Use Single NAT Gateway** (dev/staging):
```hcl
create_nat_gateway = true
single_nat_gateway = true  # Share across AZs
```

3. **Optimize Data Transfer**:
```bash
# Use CloudFront for static content
# Use Direct Connect for large transfers
# Compress data before transfer
```

## Best Practices

### 1. Network Design

✅ **Plan CIDR blocks carefully**
```
# Good: Non-overlapping, room for growth
Dev: 10.0.0.0/16
Staging: 10.1.0.0/16
Prod: 10.2.0.0/16

# Bad: Overlapping
Dev: 10.0.0.0/16
Staging: 10.0.0.0/16  # Conflict!
```

✅ **Use multiple availability zones**
```hcl
availability_zones = 3  # Production
availability_zones = 2  # Staging
```

✅ **Separate tiers with subnets**
```
Public: Web/Load Balancers
Private: Application Servers
Database: Database Servers
```

✅ **Reserve IP space for future growth**
```
# Use /16 for production
# Allows 65,536 IPs
vpc_cidr = "10.0.0.0/16"
```

### 2. Security

✅ **Use security groups as primary firewall**
```hcl
# Stateful, easier to manage
# Allow only necessary traffic
# Use descriptive names
```

✅ **Implement defense in depth**
```
1. Network ACLs (subnet level)
2. Security Groups (instance level)
3. Host-based firewalls
4. Application-level security
```

✅ **Enable VPC Flow Logs**
```hcl
enable_flow_logs = true
flow_logs_retention_days = 90
```

✅ **Use private subnets for sensitive resources**
```hcl
# Databases, application servers
# No direct internet access
# Access via NAT Gateway or VPN
```

✅ **Implement least privilege**
```bash
# Security groups: Allow only required ports
# IAM roles: Minimum permissions
# Network ACLs: Explicit deny rules
```

### 3. High Availability

✅ **Deploy across multiple AZs**
```hcl
availability_zones = 3

public_subnet_cidrs = [
  "10.0.1.0/24",  # AZ-a
  "10.0.2.0/24",  # AZ-b
  "10.0.3.0/24"   # AZ-c
]
```

✅ **Use NAT Gateway per AZ**
```hcl
create_nat_gateway = true
one_nat_gateway_per_az = true
```

✅ **Implement redundancy**
```
- Multiple NAT Gateways
- Multiple VPN connections
- Multiple Direct Connect connections
```

### 4. Cost Optimization

✅ **Use VPC Endpoints**
```hcl
# Save NAT Gateway costs
enable_s3_endpoint = true
enable_dynamodb_endpoint = true

vpc_endpoints = {
  ecr_api = { service = "ecr.api" }
  ecr_dkr = { service = "ecr.dkr" }
}
```

✅ **Right-size NAT Gateways**
```hcl
# Dev: Single NAT Gateway
single_nat_gateway = true

# Prod: One per AZ
one_nat_gateway_per_az = true
```

✅ **Monitor data transfer**
```bash
# Track NAT Gateway usage
# Optimize application data transfer
# Use CloudFront for static content
```

✅ **Clean up unused resources**
```bash
# Delete unused Elastic IPs
# Remove unused NAT Gateways
# Delete unused VPC endpoints
```

### 5. Monitoring

✅ **Enable VPC Flow Logs**
```hcl
enable_flow_logs = true
flow_logs_destination_type = "s3"  # Cheaper than CloudWatch
```

✅ **Set up CloudWatch alarms**
```bash
# NAT Gateway packet drops
# VPN tunnel status
# Network ACL denials
```

✅ **Monitor key metrics**
```bash
# NAT Gateway bytes processed
# VPN tunnel state
# VPC endpoint usage
# Flow log analysis
```

✅ **Regular security audits**
```bash
# Review security group rules
# Check network ACL rules
# Analyze flow logs for anomalies
# Review IAM permissions
```

### 6. Documentation

✅ **Document network architecture**
```
- CIDR blocks and subnets
- Route tables and routes
- Security groups and rules
- VPC endpoints
- Peering connections
```

✅ **Maintain IP address management**
```
- Track subnet allocations
- Document reserved IPs
- Plan for growth
```

✅ **Document connectivity**
```
- VPN configurations
- Direct Connect details
- Peering relationships
- Transit Gateway attachments
```

## Maintenance Tasks

### Daily Tasks
- [ ] Monitor CloudWatch alarms
- [ ] Review VPC Flow Logs for anomalies
- [ ] Check NAT Gateway health

### Weekly Tasks
- [ ] Review security group rules
- [ ] Check network ACL rules
- [ ] Monitor data transfer costs
- [ ] Review VPC endpoint usage

### Monthly Tasks
- [ ] Audit security configurations
- [ ] Review and optimize costs
- [ ] Update documentation
- [ ] Test disaster recovery procedures
- [ ] Review IP address usage

### Quarterly Tasks
- [ ] Security audit
- [ ] Architecture review
- [ ] Capacity planning
- [ ] Update network diagrams
- [ ] Review compliance requirements

## Network Diagrams

### Basic VPC Architecture
```
┌─────────────────────────────────────────────────────────┐
│                         VPC                              │
│                    10.0.0.0/16                          │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Internet Gateway                     │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │                                    │
│  ┌──────────────────┴───────────────────────────────┐  │
│  │           Public Subnets (10.0.1.0/24)           │  │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────────┐    │  │
│  │  │   ALB   │  │   ALB   │  │ NAT Gateway  │    │  │
│  │  └─────────┘  └─────────┘  └──────┬───────┘    │  │
│  └───────────────────────────────────┼────────────┘  │
│                                       │                 │
│  ┌────────────────────────────────────┼────────────┐  │
│  │        Private Subnets (10.0.11.0/24)           │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐         │  │
│  │  │  App 1  │  │  App 2  │  │  App 3  │         │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘         │  │
│  └───────┼────────────┼────────────┼──────────────┘  │
│          │            │            │                   │
│  ┌───────┴────────────┴────────────┴──────────────┐  │
│  │      Database Subnets (10.0.21.0/24)           │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐        │  │
│  │  │  RDS 1  │  │  RDS 2  │  │  RDS 3  │        │  │
│  │  └─────────┘  └─────────┘  └─────────┘        │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Multi-AZ High Availability
```
┌─────────────────────────────────────────────────────────────────┐
│                            VPC (10.0.0.0/16)                     │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   AZ-1a      │  │   AZ-1b      │  │   AZ-1c      │         │
│  │              │  │              │  │              │         │
│  │ Public       │  │ Public       │  │ Public       │         │
│  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │  │ 10.0.3.0/24  │         │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │         │
│  │ │   NAT    │ │  │ │   NAT    │ │  │ │   NAT    │ │         │
│  │ │ Gateway  │ │  │ │ Gateway  │ │  │ │ Gateway  │ │         │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │         │
│  │              │  │              │  │              │         │
│  │ Private      │  │ Private      │  │ Private      │         │
│  │ 10.0.11.0/24 │  │ 10.0.12.0/24 │  │ 10.0.13.0/24 │         │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │         │
│  │ │   App    │ │  │ │   App    │ │  │ │   App    │ │         │
│  │ │ Servers  │ │  │ │ Servers  │ │  │ │ Servers  │ │         │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │         │
│  │              │  │              │  │              │         │
│  │ Database     │  │ Database     │  │ Database     │         │
│  │ 10.0.21.0/24 │  │ 10.0.22.0/24 │  │ 10.0.23.0/24 │         │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │         │
│  │ │   RDS    │ │  │ │   RDS    │ │  │ │   RDS    │ │         │
│  │ │ Primary  │ │  │ │ Standby  │ │  │ │ Replica  │ │         │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Cleanup and Destroy

### Before Destroying

⚠️ **CRITICAL**: VPC deletion requires all resources to be removed first. This is a complex process.

**Pre-Destruction Checklist**:
- [ ] **Terminate all EC2 instances** in the VPC
- [ ] **Delete all RDS instances** in the VPC
- [ ] **Delete all EKS clusters** in the VPC
- [ ] **Delete all load balancers** (ALB, NLB, CLB)
- [ ] **Delete all NAT Gateways**
- [ ] **Release all Elastic IPs**
- [ ] **Delete all VPC endpoints**
- [ ] **Delete all Lambda functions** in the VPC
- [ ] **Delete all network interfaces**
- [ ] **Delete all security groups** (except default)
- [ ] **Delete VPC peering connections**
- [ ] **Detach and delete internet gateways**
- [ ] **Delete subnets**
- [ ] **Delete route tables** (except main)
- [ ] Notify team members
- [ ] Document VPC configuration

### Method 1: Via GitHub Actions (Recommended)

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → VPC Infrastructure
   ```

2. **Click "Run workflow"**

3. **Configure destroy settings**:
   ```yaml
   Action: destroy
   Environment: dev  # or staging/prod
   VPC Name: app-vpc  # Must match existing
   VPC CIDR: 10.0.0.0/16  # Must match existing
   Availability Zones: 2  # Must match existing
   Create NAT Gateway: true  # Must match existing
   Enable VPC Flow Logs: true  # Must match existing
   AWS Region: us-east-1  # Must match existing
   ```

4. **Important**: VPC must be empty
   - All resources must be deleted first
   - Workflow will fail if VPC contains resources

5. **Review destroy plan**
   - Workflow will show what will be destroyed
   - Verify the VPC ID is correct

6. **Approve and execute** (for prod environment)
   - Production requires manual approval
   - **Double-check VPC name** before approving

7. **Monitor destruction**
   - Watch the workflow logs
   - May take 5-10 minutes

**Expected Output**:
```
✅ VPC Destroyed Successfully!

Destroyed Resources:
- VPC: vpc-0123456789abcdef0
- Subnets: 6 subnets deleted
- Route Tables: 4 route tables deleted
- Internet Gateway: igw-xxx deleted
- NAT Gateways: 2 NAT gateways deleted
- Security Groups: 3 security groups deleted
- Network ACLs: 2 network ACLs deleted

Cleanup completed in 8 minutes.
```

### Method 2: Via AWS CLI (Step-by-Step)

#### Step 1: Identify VPC and Resources

```bash
VPC_ID="vpc-0123456789abcdef0"

# Get VPC details
aws ec2 describe-vpcs --vpc-ids $VPC_ID

# List all resources in VPC
echo "=== EC2 Instances ==="
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].[NatGatewayId,State]' \
  --output table

echo "=== Load Balancers ==="
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].[LoadBalancerArn,LoadBalancerName]" \
  --output table

echo "=== RDS Instances ==="
aws rds describe-db-instances \
  --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].[DBInstanceIdentifier,DBInstanceStatus]" \
  --output table

echo "=== VPC Endpoints ==="
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[*].[VpcEndpointId,ServiceName,State]' \
  --output table
```

#### Step 2: Delete EC2 Instances

```bash
# Get all instance IDs
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

# Terminate instances
if [ ! -z "$INSTANCE_IDS" ]; then
  echo "Terminating instances: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
  echo "Instances terminated"
fi
```

#### Step 3: Delete Load Balancers

```bash
# Delete Application/Network Load Balancers
LB_ARNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
  --output text)

for LB_ARN in $LB_ARNS; do
  echo "Deleting load balancer: $LB_ARN"
  aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
done

# Wait for deletion
sleep 60

# Delete Classic Load Balancers
CLB_NAMES=$(aws elb describe-load-balancers \
  --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" \
  --output text)

for CLB_NAME in $CLB_NAMES; do
  echo "Deleting classic load balancer: $CLB_NAME"
  aws elb delete-load-balancer --load-balancer-name $CLB_NAME
done
```

#### Step 4: Delete RDS Instances

```bash
# Delete RDS instances
DB_INSTANCES=$(aws rds describe-db-instances \
  --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].DBInstanceIdentifier" \
  --output text)

for DB_ID in $DB_INSTANCES; do
  echo "Deleting RDS instance: $DB_ID"
  aws rds delete-db-instance \
    --db-instance-identifier $DB_ID \
    --skip-final-snapshot \
    --delete-automated-backups
done

# Wait for deletion
for DB_ID in $DB_INSTANCES; do
  aws rds wait db-instance-deleted --db-instance-identifier $DB_ID
done

# Delete DB subnet groups
DB_SUBNET_GROUPS=$(aws rds describe-db-subnet-groups \
  --query "DBSubnetGroups[?VpcId=='$VPC_ID'].DBSubnetGroupName" \
  --output text)

for SG_NAME in $DB_SUBNET_GROUPS; do
  echo "Deleting DB subnet group: $SG_NAME"
  aws rds delete-db-subnet-group --db-subnet-group-name $SG_NAME
done
```

#### Step 5: Delete EKS Clusters

```bash
# List EKS clusters in VPC
EKS_CLUSTERS=$(aws eks list-clusters --query 'clusters' --output text)

for CLUSTER in $EKS_CLUSTERS; do
  CLUSTER_VPC=$(aws eks describe-cluster \
    --name $CLUSTER \
    --query 'cluster.resourcesVpcConfig.vpcId' \
    --output text)
  
  if [ "$CLUSTER_VPC" == "$VPC_ID" ]; then
    echo "Deleting EKS cluster: $CLUSTER"
    
    # Delete node groups first
    NODE_GROUPS=$(aws eks list-nodegroups \
      --cluster-name $CLUSTER \
      --query 'nodegroups' \
      --output text)
    
    for NG in $NODE_GROUPS; do
      aws eks delete-nodegroup --cluster-name $CLUSTER --nodegroup-name $NG
    done
    
    # Wait for node groups to delete
    for NG in $NODE_GROUPS; do
      aws eks wait nodegroup-deleted --cluster-name $CLUSTER --nodegroup-name $NG
    done
    
    # Delete cluster
    aws eks delete-cluster --name $CLUSTER
    aws eks wait cluster-deleted --name $CLUSTER
  fi
done
```

#### Step 6: Delete NAT Gateways

```bash
# Get NAT Gateway IDs
NAT_GW_IDS=$(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text)

# Delete NAT Gateways
for NAT_ID in $NAT_GW_IDS; do
  echo "Deleting NAT Gateway: $NAT_ID"
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
done

# Wait for deletion (takes a few minutes)
echo "Waiting for NAT Gateways to delete..."
sleep 120

# Release Elastic IPs
EIP_ALLOC_IDS=$(aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query "Addresses[?NetworkInterfaceId==null].AllocationId" \
  --output text)

for EIP_ID in $EIP_ALLOC_IDS; do
  echo "Releasing Elastic IP: $EIP_ID"
  aws ec2 release-address --allocation-id $EIP_ID
done
```

#### Step 7: Delete VPC Endpoints

```bash
# Get VPC Endpoint IDs
VPC_ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[*].VpcEndpointId' \
  --output text)

# Delete VPC Endpoints
for VPCE_ID in $VPC_ENDPOINT_IDS; do
  echo "Deleting VPC Endpoint: $VPCE_ID"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE_ID
done
```

#### Step 8: Delete Network Interfaces

```bash
# Get network interface IDs
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' \
  --output text)

# Delete network interfaces
for ENI_ID in $ENI_IDS; do
  echo "Deleting network interface: $ENI_ID"
  aws ec2 delete-network-interface --network-interface-id $ENI_ID 2>/dev/null || true
done
```

#### Step 9: Delete Security Groups

```bash
# Get security group IDs (except default)
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text)

# Delete security groups (may need multiple passes due to dependencies)
for i in {1..3}; do
  for SG_ID in $SG_IDS; do
    echo "Attempt $i: Deleting security group: $SG_ID"
    aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null || true
  done
  sleep 5
done
```

#### Step 10: Delete VPC Peering Connections

```bash
# Get peering connection IDs
PEERING_IDS=$(aws ec2 describe-vpc-peering-connections \
  --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" \
  --query 'VpcPeeringConnections[*].VpcPeeringConnectionId' \
  --output text)

# Delete peering connections
for PEER_ID in $PEERING_IDS; do
  echo "Deleting VPC peering connection: $PEER_ID"
  aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEER_ID
done
```

#### Step 11: Detach and Delete Internet Gateway

```bash
# Get Internet Gateway ID
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text)

if [ "$IGW_ID" != "None" ]; then
  echo "Detaching Internet Gateway: $IGW_ID"
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
  
  echo "Deleting Internet Gateway: $IGW_ID"
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
fi
```

#### Step 12: Delete Subnets

```bash
# Get subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text)

# Delete subnets
for SUBNET_ID in $SUBNET_IDS; do
  echo "Deleting subnet: $SUBNET_ID"
  aws ec2 delete-subnet --subnet-id $SUBNET_ID
done
```

#### Step 13: Delete Route Tables

```bash
# Get route table IDs (except main)
RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
  --output text)

# Delete route tables
for RT_ID in $RT_IDS; do
  echo "Deleting route table: $RT_ID"
  aws ec2 delete-route-table --route-table-id $RT_ID
done
```

#### Step 14: Delete VPC

```bash
# Finally, delete the VPC
echo "Deleting VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "VPC deleted successfully!"
```

### Automated Cleanup Script

```bash
#!/bin/bash
# delete-vpc.sh - Automated VPC deletion script

set -e

VPC_ID="$1"

if [ -z "$VPC_ID" ]; then
  echo "Usage: $0 <vpc-id>"
  exit 1
fi

echo "Starting VPC deletion process for: $VPC_ID"
echo "This may take 10-15 minutes..."

# Function to wait for resource deletion
wait_for_deletion() {
  local resource_type=$1
  local check_command=$2
  echo "Waiting for $resource_type to be deleted..."
  while eval "$check_command" 2>/dev/null; do
    sleep 10
  done
}

# 1. Terminate EC2 instances
echo "Step 1: Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

if [ ! -z "$INSTANCE_IDS" ]; then
  aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
  aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
fi

# 2. Delete Load Balancers
echo "Step 2: Deleting load balancers..."
LB_ARNS=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" \
  --output text)

for LB_ARN in $LB_ARNS; do
  aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
done
sleep 60

# 3. Delete NAT Gateways
echo "Step 3: Deleting NAT Gateways..."
NAT_GW_IDS=$(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' \
  --output text)

for NAT_ID in $NAT_GW_IDS; do
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
done
sleep 120

# 4. Release Elastic IPs
echo "Step 4: Releasing Elastic IPs..."
EIP_ALLOC_IDS=$(aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query "Addresses[?NetworkInterfaceId==null].AllocationId" \
  --output text)

for EIP_ID in $EIP_ALLOC_IDS; do
  aws ec2 release-address --allocation-id $EIP_ID 2>/dev/null || true
done

# 5. Delete VPC Endpoints
echo "Step 5: Deleting VPC Endpoints..."
VPC_ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[*].VpcEndpointId' \
  --output text)

for VPCE_ID in $VPC_ENDPOINT_IDS; do
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE_ID
done

# 6. Delete Network Interfaces
echo "Step 6: Deleting network interfaces..."
sleep 30
ENI_IDS=$(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' \
  --output text)

for ENI_ID in $ENI_IDS; do
  aws ec2 delete-network-interface --network-interface-id $ENI_ID 2>/dev/null || true
done

# 7. Delete Security Groups
echo "Step 7: Deleting security groups..."
SG_IDS=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
  --output text)

for i in {1..3}; do
  for SG_ID in $SG_IDS; do
    aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null || true
  done
  sleep 5
done

# 8. Detach and Delete Internet Gateway
echo "Step 8: Deleting Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text)

if [ "$IGW_ID" != "None" ]; then
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
fi

# 9. Delete Subnets
echo "Step 9: Deleting subnets..."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text)

for SUBNET_ID in $SUBNET_IDS; do
  aws ec2 delete-subnet --subnet-id $SUBNET_ID
done

# 10. Delete Route Tables
echo "Step 10: Deleting route tables..."
RT_IDS=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
  --output text)

for RT_ID in $RT_IDS; do
  aws ec2 delete-route-table --route-table-id $RT_ID
done

# 11. Delete VPC
echo "Step 11: Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

echo "✅ VPC $VPC_ID deleted successfully!"
```

Usage:
```bash
chmod +x delete-vpc.sh
./delete-vpc.sh vpc-0123456789abcdef0
```

### Verify Cleanup

```bash
# Verify VPC is deleted
aws ec2 describe-vpcs --vpc-ids $VPC_ID
# Should return error: VPC not found

# Check for orphaned resources
aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID"

aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID"
```

### Cost Savings After Destruction

**Immediate Savings**:
- NAT Gateway charges stop (~$32/month per NAT Gateway)
- Elastic IP charges stop (if not attached)
- VPC endpoint charges stop (interface endpoints)
- Data transfer charges stop

**Example**:
```
Before: 2 NAT Gateways = ~$64/month
After: $0/month
Savings: $64/month or $768/year
```

### Troubleshooting Destroy Issues

#### Issue: Cannot Delete VPC - Dependencies Exist

**Error**: "The vpc has dependencies and cannot be deleted"

**Solution**:
```bash
# Find remaining dependencies
aws ec2 describe-vpc-attribute --vpc-id $VPC_ID --attribute enableDnsSupport

# Check for:
# - Running instances
# - Active load balancers
# - RDS instances
# - Lambda functions
# - Network interfaces
# - VPC endpoints

# Use the automated script above to clean up systematically
```

#### Issue: Cannot Delete Security Group

**Error**: "resource has a dependent object"

**Solution**:
```bash
# Find what's using the security group
aws ec2 describe-network-interfaces \
  --filters "Name=group-id,Values=sg-xxx"

# Security groups may reference each other
# Delete in multiple passes
for i in {1..5}; do
  aws ec2 delete-security-group --group-id sg-xxx 2>/dev/null || true
  sleep 5
done
```

#### Issue: Cannot Delete Subnet

**Error**: "The subnet has dependencies and cannot be deleted"

**Solution**:
```bash
# Find network interfaces in subnet
aws ec2 describe-network-interfaces \
  --filters "Name=subnet-id,Values=subnet-xxx"

# Delete network interfaces first
for ENI_ID in $(aws ec2 describe-network-interfaces \
  --filters "Name=subnet-id,Values=subnet-xxx" \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' \
  --output text); do
  aws ec2 delete-network-interface --network-interface-id $ENI_ID
done

# Then delete subnet
aws ec2 delete-subnet --subnet-id subnet-xxx
```

## Additional Resources

- [Amazon VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [VPC Pricing](https://aws.amazon.com/vpc/pricing/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [VPC Peering](https://docs.aws.amazon.com/vpc/latest/peering/)
- [AWS Transit Gateway](https://aws.amazon.com/transit-gateway/)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check VPC Flow Logs
- Review CloudWatch metrics
- Contact DevOps team

---

**Last Updated**: May 2026