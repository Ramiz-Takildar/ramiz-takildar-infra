# EC2 Module Usage Guide

> **Complete guide for deploying and managing Amazon EC2 instances using the Infrastructure Provisioning Platform**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Options](#configuration-options)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [Common Use Cases](#common-use-cases)
8. [Instance Management](#instance-management)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The EC2 module provisions Amazon EC2 instances with enterprise features:

- **Multiple Instance Types**: Support for all EC2 instance families
- **Auto Scaling**: Launch multiple instances with load balancing
- **Custom AMIs**: Use official or custom AMIs
- **Security**: Security groups, IAM roles, key pairs
- **Storage**: EBS volumes with encryption
- **Monitoring**: CloudWatch metrics and alarms
- **Networking**: VPC integration, public/private subnets
- **User Data**: Bootstrap scripts for initialization

## Prerequisites

### 1. AWS Resources Required

Before deploying EC2 instances, ensure you have:

- ✅ **VPC with Subnets**: At least 1 subnet (2+ for HA)
- ✅ **SSH Key Pair**: For instance access (optional)
- ✅ **AWS OIDC Provider**: Configured for GitHub Actions
- ✅ **IAM Role**: With EC2 permissions for GitHub Actions

### 2. Deploy VPC First

If you don't have a VPC, deploy one first:

```bash
# Go to GitHub Actions → VPC Infrastructure
# Run workflow with:
- Action: apply
- Environment: dev
- VPC Name: app-vpc
- VPC CIDR: 10.0.0.0/16
- Availability Zones: 2
- Create NAT Gateway: true
```

### 3. Create SSH Key Pair (Optional)

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name my-app-key \
  --query 'KeyMaterial' \
  --output text > my-app-key.pem

# Set permissions
chmod 400 my-app-key.pem
```

### 4. GitHub Secrets Required

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `VPC_ID` | VPC ID for EC2 | `vpc-0123456789abcdef0` |
| `SUBNET_IDS` | Subnet IDs (JSON array) | `["subnet-xxx", "subnet-yyy"]` |

## Quick Start

### 5-Minute Deployment

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → EC2 Infrastructure
   ```

2. **Click "Run workflow"**

3. **Use these settings**:
   ```yaml
   Action: apply
   Environment: dev
   Instance Name: web-server
   Instance Type: t3.micro
   Instance Count: 2
   AMI OS: ubuntu-22.04
   AWS Region: us-east-1
   Enable Public IP: true
   SSH Key Name: my-app-key
   ```

4. **Click "Run workflow"** and wait (~5 minutes)

5. **Connect to instance**:
   ```bash
   # Get instance IP from workflow output
   ssh -i my-app-key.pem ubuntu@<public-ip>
   ```

## Step-by-Step Deployment

### Step 1: Access GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **"EC2 Infrastructure"** from the workflows list

### Step 2: Start Workflow

1. Click the **"Run workflow"** button
2. A form will appear with deployment options

### Step 3: Configure Basic Settings

#### Action Selection
```
Action: apply
```
- **plan**: Preview changes
- **apply**: Create/update instances
- **destroy**: Terminate instances

#### Environment Selection
```
Environment: dev
```
- **dev**: Development (no approval)
- **staging**: Staging (optional approval)
- **prod**: Production (requires approval)

#### Instance Name
```
Instance Name: web-server
```
- Used for Name tag
- Helps identify instances
- Can include environment prefix

### Step 4: Select Instance Type

```
Instance Type: t3.medium
```

**Instance Type Guide**:

| Type | vCPU | RAM | Network | Use Case | Cost/Month* |
|------|------|-----|---------|----------|-------------|
| **t3.micro** | 2 | 1 GB | Low-Moderate | Dev/Test | ~$7 |
| **t3.small** | 2 | 2 GB | Low-Moderate | Small apps | ~$15 |
| **t3.medium** | 2 | 4 GB | Low-Moderate | Web servers | ~$30 |
| **t3.large** | 2 | 8 GB | Low-Moderate | Medium apps | ~$60 |
| **t3.xlarge** | 4 | 16 GB | Moderate | Large apps | ~$120 |
| **m5.large** | 2 | 8 GB | Up to 10 Gbps | General purpose | ~$70 |
| **m5.xlarge** | 4 | 16 GB | Up to 10 Gbps | Production | ~$140 |
| **c5.large** | 2 | 4 GB | Up to 10 Gbps | Compute-intensive | ~$62 |
| **r5.large** | 2 | 16 GB | Up to 10 Gbps | Memory-intensive | ~$92 |

*Approximate costs for us-east-1, Linux

**Recommendations**:
- **Dev/Test**: t3.micro, t3.small
- **Web Servers**: t3.medium, t3.large
- **Application Servers**: m5.large, m5.xlarge
- **Compute-Intensive**: c5.large, c5.xlarge
- **Memory-Intensive**: r5.large, r5.xlarge

### Step 5: Configure Instance Count

```
Instance Count: 2
```

**Guidelines**:
- **Dev**: 1 instance
- **Staging**: 2 instances
- **Production**: 3+ instances (across AZs)

**Benefits of Multiple Instances**:
- High availability
- Load distribution
- Zero-downtime deployments
- Fault tolerance

### Step 6: Select AMI

```
AMI OS: ubuntu-22.04
```

**Available AMIs**:
- **ubuntu-22.04**: Ubuntu 22.04 LTS (recommended)
- **ubuntu-20.04**: Ubuntu 20.04 LTS
- **amazon-linux-2**: Amazon Linux 2
- **amazon-linux-2023**: Amazon Linux 2023
- **rhel-8**: Red Hat Enterprise Linux 8
- **rhel-9**: Red Hat Enterprise Linux 9

**Default Users**:
- Ubuntu: `ubuntu`
- Amazon Linux: `ec2-user`
- RHEL: `ec2-user`

### Step 7: Configure Networking

#### AWS Region
```
AWS Region: us-east-1
```

#### Enable Public IP
```
Enable Public IP: true
```
- **true**: Instance gets public IP (internet access)
- **false**: Private IP only (VPC access only)

**When to Enable**:
- ✅ Web servers
- ✅ Bastion hosts
- ✅ Development instances
- ❌ Database servers
- ❌ Application servers (use load balancer)

#### SSH Key Name
```
SSH Key Name: my-app-key
```
- Must exist in AWS region
- Used for SSH access
- Optional (can use Session Manager)

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
✅ EC2 Instances Deployed Successfully!

Instance Details:
- Instance Name: web-server
- Environment: dev
- Instance Type: t3.medium
- Instance Count: 2
- AMI: ubuntu-22.04
- Region: us-east-1

Instance IDs:
- i-0123456789abcdef0
- i-0123456789abcdef1

Public IPs:
- 54.123.45.67
- 54.123.45.68

SSH Command:
ssh -i my-app-key.pem ubuntu@54.123.45.67
```

## Configuration Options

### Basic Configuration

```hcl
# Minimum required
instance_name  = "web-server"
instance_type  = "t3.medium"
instance_count = 2
subnet_ids     = ["subnet-xxx", "subnet-yyy"]

ami_os = "ubuntu-22.04"
```

### Production Configuration

```hcl
# Production-ready
instance_name  = "prod-web-server"
instance_type  = "m5.large"
instance_count = 3

# AMI
ami_os = "ubuntu-22.04"

# Storage
root_volume_size = 50
root_volume_type = "gp3"
root_volume_encrypted = true

# Additional volumes
ebs_volumes = [
  {
    device_name = "/dev/sdf"
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }
]

# Networking
subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
associate_public_ip_address = false
vpc_security_group_ids = ["sg-xxx"]

# SSH
key_name = "prod-key"

# IAM
iam_instance_profile = "prod-ec2-profile"

# Monitoring
monitoring = true
enable_cloudwatch_alarms = true

# User Data
user_data = <<-EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
EOF

# Tags
tags = {
  Environment = "production"
  Application = "web"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
```

## Post-Deployment Setup

### 1. Connect to Instance

#### Using SSH
```bash
# Get public IP from workflow output
PUBLIC_IP="54.123.45.67"

# Connect
ssh -i my-app-key.pem ubuntu@$PUBLIC_IP

# Or use specific user
ssh -i my-app-key.pem ec2-user@$PUBLIC_IP  # Amazon Linux
```

#### Using AWS Session Manager (No SSH Key Required)
```bash
# Install Session Manager plugin
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Get instance ID
INSTANCE_ID="i-0123456789abcdef0"

# Start session
aws ssm start-session --target $INSTANCE_ID
```

### 2. Verify Instance

```bash
# Check OS version
cat /etc/os-release

# Check instance metadata
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/instance-type
curl http://169.254.169.254/latest/meta-data/placement/availability-zone

# Check attached volumes
lsblk

# Check network interfaces
ip addr show
```

### 3. Install Software

#### Ubuntu/Debian
```bash
# Update packages
sudo apt-get update
sudo apt-get upgrade -y

# Install common tools
sudo apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools

# Install web server
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### Amazon Linux/RHEL
```bash
# Update packages
sudo yum update -y

# Install common tools
sudo yum install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools

# Install web server
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 4. Configure Application

```bash
# Create application directory
sudo mkdir -p /var/www/myapp
sudo chown -R ubuntu:ubuntu /var/www/myapp

# Deploy application
cd /var/www/myapp
git clone https://github.com/myorg/myapp.git .

# Install dependencies (example: Node.js app)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install

# Start application
npm start
```

### 5. Configure Load Balancer (Multiple Instances)

```bash
# Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name my-app-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx

# Create target group
aws elbv2 create-target-group \
  --name my-app-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxx

# Register instances
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-xxx Id=i-yyy
```

## Common Use Cases

### Use Case 1: Web Server

**Requirements**: Host a web application

```yaml
# Via GitHub Actions
Action: apply
Environment: prod
Instance Name: web-server
Instance Type: t3.medium
Instance Count: 2
AMI OS: ubuntu-22.04
Enable Public IP: false  # Use load balancer
```

**User Data**:
```bash
#!/bin/bash
apt-get update
apt-get install -y nginx

cat > /var/www/html/index.html <<EOF
<html>
<body>
<h1>Welcome to My App</h1>
<p>Instance: $(ec2-metadata --instance-id)</p>
</body>
</html>
EOF

systemctl start nginx
systemctl enable nginx
```

**Cost**: ~$60/month (2 t3.medium)

### Use Case 2: Application Server

**Requirements**: Run backend application

```yaml
Action: apply
Environment: prod
Instance Name: app-server
Instance Type: m5.large
Instance Count: 3
AMI OS: amazon-linux-2023
Enable Public IP: false
```

**User Data**:
```bash
#!/bin/bash
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Pull and run application
docker pull myorg/myapp:latest
docker run -d -p 8080:8080 myorg/myapp:latest
```

**Cost**: ~$210/month (3 m5.large)

### Use Case 3: Bastion Host

**Requirements**: Secure SSH access to private instances

```yaml
Action: apply
Environment: prod
Instance Name: bastion
Instance Type: t3.micro
Instance Count: 1
AMI OS: ubuntu-22.04
Enable Public IP: true
SSH Key Name: bastion-key
```

**Security Group**:
```hcl
# Allow SSH from specific IPs only
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32"]
}
```

**Usage**:
```bash
# SSH to bastion
ssh -i bastion-key.pem ubuntu@<bastion-ip>

# From bastion, SSH to private instance
ssh -i app-key.pem ubuntu@<private-ip>
```

**Cost**: ~$7/month (1 t3.micro)

### Use Case 4: Development Environment

**Requirements**: Personal development instance

```yaml
Action: apply
Environment: dev
Instance Name: dev-workstation
Instance Type: t3.large
Instance Count: 1
AMI OS: ubuntu-22.04
Enable Public IP: true
```

**User Data**:
```bash
#!/bin/bash
apt-get update
apt-get install -y \
  build-essential \
  git \
  docker.io \
  python3-pip \
  nodejs \
  npm

# Install VS Code Server
curl -fsSL https://code-server.dev/install.sh | sh
systemctl enable --now code-server@ubuntu
```

**Cost**: ~$60/month (1 t3.large)

## Instance Management

### Start/Stop Instances

```bash
# Stop instance (saves costs)
aws ec2 stop-instances --instance-ids i-xxx

# Start instance
aws ec2 start-instances --instance-ids i-xxx

# Reboot instance
aws ec2 reboot-instances --instance-ids i-xxx
```

### Resize Instance

```bash
# Stop instance first
aws ec2 stop-instances --instance-ids i-xxx
aws ec2 wait instance-stopped --instance-ids i-xxx

# Change instance type
aws ec2 modify-instance-attribute \
  --instance-id i-xxx \
  --instance-type t3.large

# Start instance
aws ec2 start-instances --instance-ids i-xxx
```

### Create AMI

```bash
# Create AMI from instance
aws ec2 create-image \
  --instance-id i-xxx \
  --name "my-app-$(date +%Y%m%d)" \
  --description "My application AMI" \
  --no-reboot

# List AMIs
aws ec2 describe-images --owners self
```

### Attach EBS Volume

```bash
# Create volume
aws ec2 create-volume \
  --availability-zone us-east-1a \
  --size 100 \
  --volume-type gp3

# Attach volume
aws ec2 attach-volume \
  --volume-id vol-xxx \
  --instance-id i-xxx \
  --device /dev/sdf

# Mount volume (on instance)
sudo mkfs -t ext4 /dev/sdf
sudo mkdir /data
sudo mount /dev/sdf /data
```

### Monitor Instance

```bash
# Get instance status
aws ec2 describe-instance-status --instance-ids i-xxx

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-xxx \
  --start-time 2026-05-16T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 3600 \
  --statistics Average
```

## Troubleshooting

### Issue 1: Cannot Connect via SSH

**Symptoms**:
```bash
ssh: connect to host 54.123.45.67 port 22: Connection timed out
```

**Diagnosis**:
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids i-xxx

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxx
```

**Solutions**:

1. **Check Security Group**:
```bash
# Add SSH rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32
```

2. **Verify Key Pair**:
```bash
# Check key permissions
ls -l my-app-key.pem  # Should be 400

# Fix permissions
chmod 400 my-app-key.pem
```

3. **Check Network ACLs**:
```bash
# Verify NACL allows SSH
aws ec2 describe-network-acls --filters "Name=vpc-id,Values=vpc-xxx"
```

### Issue 2: Instance Not Starting

**Symptoms**:
Instance stuck in "pending" state

**Diagnosis**:
```bash
# Check system log
aws ec2 get-console-output --instance-id i-xxx

# Check instance status checks
aws ec2 describe-instance-status --instance-ids i-xxx
```

**Solutions**:

1. **Check Instance Limits**:
```bash
# View service quotas
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A  # Running On-Demand instances
```

2. **Check Subnet Capacity**:
```bash
# Verify subnet has available IPs
aws ec2 describe-subnets --subnet-ids subnet-xxx
```

3. **Try Different AZ**:
```bash
# Launch in different subnet/AZ
```

### Issue 3: High CPU Usage

**Symptoms**:
CloudWatch alarm for high CPU

**Diagnosis**:
```bash
# SSH to instance
ssh -i key.pem ubuntu@<ip>

# Check processes
top
htop

# Check specific process
ps aux | grep <process-name>
```

**Solutions**:

1. **Identify Resource-Intensive Process**:
```bash
# Find top CPU consumers
ps aux --sort=-%cpu | head -10
```

2. **Optimize Application**:
```bash
# Restart application
sudo systemctl restart myapp

# Check logs
sudo journalctl -u myapp -f
```

3. **Scale Up**:
```bash
# Resize to larger instance type
# Via GitHub Actions or AWS CLI
```

### Issue 4: Disk Space Full

**Symptoms**:
```bash
df -h
# /dev/xvda1  20G  20G  0  100% /
```

**Solutions**:

1. **Clean Up**:
```bash
# Remove old logs
sudo journalctl --vacuum-time=7d

# Clean package cache
sudo apt-get clean  # Ubuntu
sudo yum clean all  # Amazon Linux

# Find large files
sudo du -h / | sort -rh | head -20
```

2. **Expand Volume**:
```bash
# Modify volume size
aws ec2 modify-volume \
  --volume-id vol-xxx \
  --size 50

# Extend filesystem (on instance)
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1
```

## Best Practices

### 1. Security

✅ **Use IAM roles instead of access keys**
```hcl
iam_instance_profile = "ec2-app-role"
```

✅ **Restrict security groups**
```hcl
# Only allow necessary ports
ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```

✅ **Enable encryption**
```hcl
root_volume_encrypted = true
```

✅ **Use Systems Manager Session Manager**
- No SSH keys needed
- Centralized access logging
- No open ports

✅ **Keep software updated**
```bash
# Ubuntu
sudo apt-get update && sudo apt-get upgrade -y

# Amazon Linux
sudo yum update -y
```

### 2. High Availability

✅ **Deploy across multiple AZs**
```hcl
subnet_ids = ["subnet-az1", "subnet-az2", "subnet-az3"]
```

✅ **Use Auto Scaling Groups**
```bash
# Create launch template
# Create Auto Scaling Group
# Configure scaling policies
```

✅ **Use load balancers**
```bash
# Application Load Balancer for HTTP/HTTPS
# Network Load Balancer for TCP/UDP
```

✅ **Implement health checks**
```bash
# ALB health check
# Auto Scaling health check
```

### 3. Cost Optimization

✅ **Right-size instances**
- Monitor CPU, memory, network
- Use CloudWatch metrics
- Downsize if consistently < 30% utilization

✅ **Use Reserved Instances**
- 1-year: ~30% savings
- 3-year: ~50% savings

✅ **Use Spot Instances for non-critical workloads**
- 70-90% cost savings
- Good for batch processing, CI/CD

✅ **Stop instances when not needed**
```bash
# Stop dev instances overnight
aws ec2 stop-instances --instance-ids i-xxx
```

✅ **Delete unused resources**
```bash
# Delete unused volumes
# Delete old snapshots
# Delete unused AMIs
```

### 4. Monitoring

✅ **Enable detailed monitoring**
```hcl
monitoring = true
```

✅ **Set up CloudWatch alarms**
```hcl
enable_cloudwatch_alarms = true
```

✅ **Monitor key metrics**
- CPU Utilization
- Network In/Out
- Disk Read/Write
- Status Checks

✅ **Use CloudWatch Logs**
```bash
# Install CloudWatch agent
# Configure log collection
# Set up log insights queries
```

### 5. Backup and Recovery

✅ **Create regular AMIs**
```bash
# Automated AMI creation
aws ec2 create-image --instance-id i-xxx --name "backup-$(date +%Y%m%d)"
```

✅ **Snapshot EBS volumes**
```bash
# Create snapshot
aws ec2 create-snapshot --volume-id vol-xxx --description "Daily backup"
```

✅ **Test recovery procedures**
```bash
# Launch instance from AMI
# Restore volume from snapshot
# Verify application functionality
```

✅ **Document recovery steps**
- RTO (Recovery Time Objective)
- RPO (Recovery Point Objective)
- Step-by-step procedures

## Maintenance Tasks

### Daily Tasks
- [ ] Monitor CloudWatch alarms
- [ ] Check instance status
- [ ] Review application logs

### Weekly Tasks
- [ ] Review CloudWatch metrics
- [ ] Check disk space usage
- [ ] Update security patches
- [ ] Review security group rules

### Monthly Tasks
- [ ] Create AMI backups
- [ ] Review instance sizing
- [ ] Optimize costs
- [ ] Update software packages
- [ ] Review IAM permissions

### Quarterly Tasks
- [ ] Test disaster recovery
- [ ] Review architecture
- [ ] Audit security configurations
- [ ] Update documentation

## Cleanup and Destroy

### Before Destroying

⚠️ **Important**: Ensure you have backups of any important data before destroying instances.

**Pre-Destruction Checklist**:
- [ ] Backup any important data
- [ ] Create AMI if needed for future use
- [ ] Document any custom configurations
- [ ] Notify team members
- [ ] Update DNS records if applicable
- [ ] Remove from monitoring systems

### Method 1: Via GitHub Actions (Recommended)

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → EC2 Infrastructure
   ```

2. **Click "Run workflow"**

3. **Configure destroy settings**:
   ```yaml
   Action: destroy
   Environment: dev  # or staging/prod
   Instance Name: web-server
   Instance Type: t3.medium  # Must match existing
   Instance Count: 2  # Must match existing
   AMI OS: ubuntu-22.04  # Must match existing
   AWS Region: us-east-1  # Must match existing
   Enable Public IP: true  # Must match existing
   SSH Key Name: my-app-key  # Must match existing
   ```

4. **Review destroy plan**
   - Workflow will show what will be destroyed
   - Verify the resources match your expectations

5. **Approve and execute** (for prod environment)
   - Production requires manual approval
   - Review the plan carefully before approving

6. **Monitor destruction**
   - Watch the workflow logs
   - Verify successful completion

**Expected Output**:
```
✅ EC2 Instances Destroyed Successfully!

Destroyed Resources:
- Instance IDs: i-0123456789abcdef0, i-0123456789abcdef1
- Security Groups: sg-xxx
- Network Interfaces: eni-xxx, eni-yyy
- EBS Volumes: vol-xxx, vol-yyy

Cleanup completed in 3 minutes.
```

### Method 2: Via AWS CLI

#### Step 1: Identify Resources

```bash
# List instances by name
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table

# Get instance IDs
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

echo "Instances to terminate: $INSTANCE_IDS"
```

#### Step 2: Create AMI (Optional)

```bash
# Create AMI before termination
for INSTANCE_ID in $INSTANCE_IDS; do
  aws ec2 create-image \
    --instance-id $INSTANCE_ID \
    --name "backup-$(date +%Y%m%d-%H%M%S)-$INSTANCE_ID" \
    --description "Backup before termination" \
    --no-reboot
done
```

#### Step 3: Terminate Instances

```bash
# Terminate instances
aws ec2 terminate-instances --instance-ids $INSTANCE_IDS

# Wait for termination
aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS

echo "Instances terminated successfully"
```

#### Step 4: Clean Up Associated Resources

```bash
# Delete security groups (after instances are terminated)
SG_ID="sg-xxx"
aws ec2 delete-security-group --group-id $SG_ID

# Delete key pair (if no longer needed)
aws ec2 delete-key-pair --key-name my-app-key

# Delete EBS volumes (if not auto-deleted)
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,State]' \
  --output table

# Delete specific volume
aws ec2 delete-volume --volume-id vol-xxx

# Delete snapshots (if created)
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[*].[SnapshotId,StartTime,Description]' \
  --output table

aws ec2 delete-snapshot --snapshot-id snap-xxx
```

### Method 3: Via Terraform (Direct)

```bash
# Navigate to environment directory
cd terraform/environments/dev/ec2

# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy -auto-approve

# Or destroy specific resource
terraform destroy -target=module.ec2
```

### Partial Cleanup

#### Stop Instances (Keep for Later)

```bash
# Stop instances instead of terminating
aws ec2 stop-instances --instance-ids $INSTANCE_IDS

# Instances can be restarted later
aws ec2 start-instances --instance-ids $INSTANCE_IDS
```

#### Detach and Keep EBS Volumes

```bash
# Detach volume before terminating instance
aws ec2 detach-volume --volume-id vol-xxx

# Modify instance to not delete volume on termination
aws ec2 modify-instance-attribute \
  --instance-id i-xxx \
  --block-device-mappings \
    "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"DeleteOnTermination\":false}}]"
```

### Verify Cleanup

```bash
# Verify no instances remain
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=web-server" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table

# Check for orphaned volumes
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table

# Check for orphaned network interfaces
aws ec2 describe-network-interfaces \
  --filters "Name=status,Values=available" \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,PrivateIpAddress]' \
  --output table

# Check for orphaned Elastic IPs
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
  --output table
```

### Cost Savings After Destruction

**Immediate Savings**:
- EC2 instance charges stop immediately
- EBS volume charges stop (if deleted)
- Data transfer charges stop
- Elastic IP charges stop (if released)

**Example**:
```
Before: 2 × t3.medium = ~$60/month
After: $0/month
Savings: $60/month or $720/year
```

### Troubleshooting Destroy Issues

#### Issue: Cannot Terminate Instance

**Error**: "Instance is protected from termination"

**Solution**:
```bash
# Disable termination protection
aws ec2 modify-instance-attribute \
  --instance-id i-xxx \
  --no-disable-api-termination

# Now terminate
aws ec2 terminate-instances --instance-ids i-xxx
```

#### Issue: Security Group Cannot Be Deleted

**Error**: "resource has a dependent object"

**Solution**:
```bash
# Find dependencies
aws ec2 describe-network-interfaces \
  --filters "Name=group-id,Values=sg-xxx"

# Terminate instances using the security group first
# Then delete security group
aws ec2 delete-security-group --group-id sg-xxx
```

#### Issue: Volume Cannot Be Deleted

**Error**: "Volume is in use"

**Solution**:
```bash
# Check volume attachments
aws ec2 describe-volumes --volume-ids vol-xxx

# Detach volume
aws ec2 detach-volume --volume-id vol-xxx

# Wait for detachment
aws ec2 wait volume-available --volume-ids vol-xxx

# Delete volume
aws ec2 delete-volume --volume-id vol-xxx
```

## Additional Resources

- [Amazon EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)
- [AWS Systems Manager](https://docs.aws.amazon.com/systems-manager/)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check AWS CloudWatch logs
- Contact DevOps team

---

**Last Updated**: May 2026
