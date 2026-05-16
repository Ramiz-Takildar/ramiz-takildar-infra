# EC2 Instance Module

This Terraform module creates and manages AWS EC2 instances with enterprise-grade features and best practices.

## Features

- ✅ Multiple instance support with automatic distribution across subnets
- ✅ Custom AMI selection or automatic latest AMI discovery
- ✅ Security group creation with customizable ingress/egress rules
- ✅ SSH key pair management
- ✅ IAM instance profile with managed and custom policies
- ✅ EBS volume configuration (root and additional volumes)
- ✅ Elastic IP allocation and association
- ✅ CloudWatch monitoring and alarms
- ✅ IMDSv2 enforcement for enhanced security
- ✅ User data script support
- ✅ Comprehensive tagging strategy
- ✅ T2/T3 CPU credit specification
- ✅ Encryption at rest for all volumes

## Supported Operating Systems

- **Ubuntu**: 20.04, 22.04
- **Amazon Linux**: 2, 2023
- **RHEL**: 8, 9

## Usage

### Basic Example

```hcl
module "ec2" {
  source = "../../modules/ec2"

  instance_name  = "web-server"
  instance_type  = "t3.micro"
  instance_count = 2
  subnet_ids     = ["subnet-12345678", "subnet-87654321"]
  
  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

### Complete Example with All Features

```hcl
module "ec2" {
  source = "../../modules/ec2"

  # General Configuration
  instance_name  = "app-server"
  instance_type  = "t3.medium"
  instance_count = 3

  # Network Configuration
  subnet_ids                  = ["subnet-12345678", "subnet-87654321", "subnet-11223344"]
  vpc_id                      = "vpc-12345678"
  associate_public_ip_address = true
  allocate_eip                = true

  # AMI Configuration
  ami_name_filter = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  ami_owner       = "099720109477" # Canonical
  architecture    = "x86_64"

  # Security Group Configuration
  create_security_group = true
  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      description = "SSH from internal network"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    }
  ]

  # SSH Key Pair
  create_key_pair = true
  key_pair_name   = "app-server-key"
  public_key      = file("~/.ssh/id_rsa.pub")

  # Storage Configuration
  root_volume_type      = "gp3"
  root_volume_size      = 30
  root_volume_encrypted = true
  
  ebs_block_devices = [
    {
      device_name = "/dev/sdf"
      volume_size = 100
      volume_type = "gp3"
      encrypted   = true
    }
  ]

  # IAM Configuration
  create_iam_instance_profile = true
  iam_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  # User Data
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  # Monitoring
  enable_detailed_monitoring = true
  enable_cloudwatch_alarms   = true
  cpu_alarm_threshold        = 80

  # Security
  metadata_http_tokens                 = "required" # IMDSv2
  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "stop"

  # Tags
  tags = {
    Environment = "production"
    Project     = "web-app"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}
```

### Amazon Linux 2 Example

```hcl
module "ec2_amazon_linux" {
  source = "../../modules/ec2"

  instance_name  = "app-server"
  instance_type  = "t3.small"
  instance_count = 1
  subnet_ids     = ["subnet-12345678"]

  # Amazon Linux 2 AMI
  ami_name_filter = "amzn2-ami-hvm-*-x86_64-gp2"
  ami_owner       = "137112412989" # Amazon

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Environment = "dev"
    OS          = "Amazon Linux 2"
  }
}
```

### RHEL Example

```hcl
module "ec2_rhel" {
  source = "../../modules/ec2"

  instance_name  = "rhel-server"
  instance_type  = "t3.medium"
  instance_count = 1
  subnet_ids     = ["subnet-12345678"]

  # RHEL 9 AMI
  ami_name_filter = "RHEL-9*_HVM-*-x86_64-*"
  ami_owner       = "309956199498" # Red Hat

  tags = {
    Environment = "production"
    OS          = "RHEL 9"
  }
}
```

### High-Performance Instance with io2 Volumes

```hcl
module "ec2_high_performance" {
  source = "../../modules/ec2"

  instance_name  = "database-server"
  instance_type  = "r6i.xlarge"
  instance_count = 1
  subnet_ids     = ["subnet-12345678"]

  # High-performance storage
  root_volume_type = "io2"
  root_volume_size = 100
  root_volume_iops = 10000

  ebs_block_devices = [
    {
      device_name = "/dev/sdf"
      volume_size = 500
      volume_type = "io2"
      iops        = 20000
      encrypted   = true
    }
  ]

  # Dedicated tenancy for compliance
  tenancy = "dedicated"

  tags = {
    Environment = "production"
    Workload    = "database"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| instance_name | Name prefix for EC2 instances | `string` | n/a | yes |
| instance_count | Number of EC2 instances to create | `number` | `1` | no |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| subnet_ids | List of subnet IDs where instances will be launched | `list(string)` | n/a | yes |
| ami_id | AMI ID to use for the instance | `string` | `""` | no |
| ami_name_filter | Name filter to find the latest AMI | `string` | `"ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"` | no |
| ami_owner | Owner ID for AMI filter | `string` | `"099720109477"` | no |
| vpc_id | VPC ID where security group will be created | `string` | `""` | no |
| create_security_group | Create a new security group for the instances | `bool` | `true` | no |
| security_group_ids | List of security group IDs to attach | `list(string)` | `[]` | no |
| ingress_rules | List of ingress rules for the security group | `list(object)` | See variables.tf | no |
| egress_rules | List of egress rules for the security group | `list(object)` | See variables.tf | no |
| create_key_pair | Create a new SSH key pair | `bool` | `false` | no |
| key_pair_name | Name of the SSH key pair | `string` | `""` | no |
| public_key | Public key material for SSH key pair | `string` | `""` | no |
| root_volume_type | Type of root volume | `string` | `"gp3"` | no |
| root_volume_size | Size of root volume in GB | `number` | `20` | no |
| root_volume_encrypted | Enable encryption for root volume | `bool` | `true` | no |
| ebs_block_devices | Additional EBS block devices | `list(object)` | `[]` | no |
| user_data | User data script to run on instance launch | `string` | `""` | no |
| create_iam_instance_profile | Create IAM instance profile | `bool` | `false` | no |
| iam_managed_policy_arns | List of IAM managed policy ARNs | `list(string)` | See variables.tf | no |
| associate_public_ip_address | Associate a public IP address | `bool` | `false` | no |
| allocate_eip | Allocate and associate Elastic IP | `bool` | `false` | no |
| enable_detailed_monitoring | Enable detailed CloudWatch monitoring | `bool` | `false` | no |
| enable_cloudwatch_alarms | Create CloudWatch alarms | `bool` | `false` | no |
| metadata_http_tokens | Require IMDSv2 | `string` | `"required"` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_ids | List of EC2 instance IDs |
| instance_arns | List of EC2 instance ARNs |
| instance_private_ips | List of private IP addresses |
| instance_public_ips | List of public IP addresses |
| instance_private_dns | List of private DNS names |
| instance_public_dns | List of public DNS names |
| security_group_id | ID of the security group |
| iam_role_arn | ARN of the IAM role |
| key_pair_name | Name of the SSH key pair |
| ssh_connection_strings | SSH connection strings |
| instance_summary | Summary of all created instances |

## AMI Owner IDs

| Operating System | Owner ID | Description |
|-----------------|----------|-------------|
| Ubuntu | 099720109477 | Canonical |
| Amazon Linux | 137112412989 | Amazon |
| RHEL | 309956199498 | Red Hat |
| Windows | 801119661308 | Amazon |

## Common AMI Name Filters

| OS | Filter |
|----|--------|
| Ubuntu 22.04 | `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` |
| Ubuntu 20.04 | `ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*` |
| Amazon Linux 2 | `amzn2-ami-hvm-*-x86_64-gp2` |
| Amazon Linux 2023 | `al2023-ami-*-x86_64` |
| RHEL 9 | `RHEL-9*_HVM-*-x86_64-*` |
| RHEL 8 | `RHEL-8*_HVM-*-x86_64-*` |

## Security Best Practices

1. **IMDSv2**: Always use `metadata_http_tokens = "required"` to enforce IMDSv2
2. **Encryption**: Enable encryption for all EBS volumes
3. **IAM Roles**: Use IAM roles instead of access keys
4. **Security Groups**: Follow principle of least privilege
5. **SSH Keys**: Use SSH keys instead of passwords
6. **Monitoring**: Enable detailed monitoring and CloudWatch alarms
7. **Updates**: Keep AMIs and packages up to date
8. **Backups**: Enable EBS snapshots for critical data

## Cost Optimization

1. **Instance Type**: Choose appropriate instance type for workload
2. **CPU Credits**: Use `unlimited` mode for T2/T3 only when needed
3. **EBS Volumes**: Use gp3 instead of gp2 for better price/performance
4. **Elastic IPs**: Release unused Elastic IPs
5. **Monitoring**: Use basic monitoring unless detailed metrics are required
6. **Reserved Instances**: Consider Reserved Instances for long-running workloads

## Troubleshooting

### Instance fails to launch

- Check subnet has available IP addresses
- Verify security group rules
- Ensure AMI is available in the region
- Check IAM permissions

### Cannot connect via SSH

- Verify security group allows SSH (port 22)
- Check key pair is correct
- Ensure instance has public IP or Elastic IP
- Verify network ACLs

### User data script not running

- Check CloudWatch logs: `/var/log/cloud-init-output.log`
- Verify script syntax
- Ensure script has proper shebang (`#!/bin/bash`)
- Check IAM permissions for script actions

## License

This module is maintained by the DevOps team and is available under the MIT License.

## Authors

- DevOps Team

## Support

For issues and questions, please contact the DevOps team or create an issue in the repository.
