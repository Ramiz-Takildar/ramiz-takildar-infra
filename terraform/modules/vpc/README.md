# VPC Module

This Terraform module creates a complete AWS VPC infrastructure with enterprise-grade networking features and high availability.

## Features

- ✅ Multi-AZ deployment for high availability
- ✅ Public, private, and database subnet tiers
- ✅ Internet Gateway for public internet access
- ✅ NAT Gateways for private subnet internet access
- ✅ Automatic subnet CIDR calculation
- ✅ VPC Flow Logs for network monitoring
- ✅ VPC Endpoints (S3, DynamoDB) for cost optimization
- ✅ Custom DHCP options
- ✅ Database subnet groups for RDS
- ✅ Secure default security group and NACL
- ✅ Comprehensive tagging strategy
- ✅ Cost optimization options

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Internet Gateway                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                            │                                │
│  ┌─────────────────────────┴────────────────────────────┐  │
│  │              Public Subnets (10.0.0.0/24)            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │   AZ-1   │  │   AZ-2   │  │   AZ-3   │          │  │
│  │  │ NAT GW   │  │ NAT GW   │  │ NAT GW   │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │             Private Subnets (10.0.3.0/24)            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │   AZ-1   │  │   AZ-2   │  │   AZ-3   │          │  │
│  │  │  App     │  │  App     │  │  App     │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Database Subnets (10.0.6.0/24)            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │   AZ-1   │  │   AZ-2   │  │   AZ-3   │          │  │
│  │  │   RDS    │  │   RDS    │  │   RDS    │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              VPC Endpoints (Optional)                 │  │
│  │         S3 Gateway  │  DynamoDB Gateway               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic VPC (Development)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "dev-vpc"
  vpc_cidr = "10.0.0.0/16"
  
  max_availability_zones = 2
  single_nat_gateway     = true  # Cost optimization
  
  tags = {
    Environment = "development"
    Project     = "my-app"
  }
}
```

### Production VPC (High Availability)

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "prod-vpc"
  vpc_cidr = "10.0.0.0/16"
  
  # High Availability Configuration
  max_availability_zones = 3
  single_nat_gateway     = false  # NAT Gateway per AZ
  
  # Subnet Configuration
  create_public_subnets   = true
  create_private_subnets  = true
  create_database_subnets = true
  
  # Security and Monitoring
  enable_flow_logs = true
  flow_logs_traffic_type = "ALL"
  flow_logs_retention_days = 30
  
  # VPC Endpoints for cost optimization
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  tags = {
    Environment = "production"
    Project     = "my-app"
    Compliance  = "SOC2"
  }
}
```

### Complete Example with All Features

```hcl
module "vpc" {
  source = "../../modules/vpc"

  # Basic Configuration
  vpc_name = "app-vpc"
  vpc_cidr = "10.1.0.0/16"
  
  # VPC Settings
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  
  # Availability Zones
  max_availability_zones = 3
  
  # Subnet Configuration
  create_public_subnets   = true
  create_private_subnets  = true
  create_database_subnets = true
  
  # Subnet CIDR Calculation
  public_subnet_bits   = 8  # /24 subnets (256 IPs)
  private_subnet_bits  = 8  # /24 subnets (256 IPs)
  database_subnet_bits = 8  # /24 subnets (256 IPs)
  
  # Public Subnet Settings
  map_public_ip_on_launch = true
  
  # Internet Gateway
  create_internet_gateway = true
  
  # NAT Gateway Configuration
  create_nat_gateway = true
  single_nat_gateway = false  # One per AZ for HA
  
  # Database Configuration
  create_database_route_table   = true
  create_database_subnet_group  = true
  
  # VPC Flow Logs
  enable_flow_logs         = true
  flow_logs_traffic_type   = "ALL"
  flow_logs_retention_days = 30
  
  # VPC Endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  # DHCP Options
  enable_dhcp_options              = true
  dhcp_options_domain_name         = "example.internal"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]
  
  # Additional Subnet Tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
  
  # Common Tags
  tags = {
    Environment        = "production"
    Project            = "web-app"
    ManagedBy          = "Terraform"
    CostCenter         = "engineering"
    DataClassification = "internal"
  }
}
```

### VPC for EKS Cluster

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "eks-vpc"
  vpc_cidr = "10.2.0.0/16"
  
  max_availability_zones = 3
  single_nat_gateway     = false
  
  # EKS requires specific subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/my-eks-cluster"      = "shared"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/my-eks-cluster"      = "shared"
  }
  
  # Enable VPC endpoints for cost savings
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  tags = {
    Environment = "production"
    Project     = "eks-cluster"
  }
}
```

### Multi-Tier Application VPC

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "multi-tier-vpc"
  vpc_cidr = "10.3.0.0/16"
  
  # Three-tier architecture
  create_public_subnets   = true  # Web tier
  create_private_subnets  = true  # Application tier
  create_database_subnets = true  # Database tier
  
  max_availability_zones = 3
  single_nat_gateway     = false
  
  # Separate route table for database tier
  create_database_route_table  = true
  create_database_subnet_group = true
  
  # Security and compliance
  enable_flow_logs         = true
  flow_logs_traffic_type   = "ALL"
  flow_logs_retention_days = 90
  
  tags = {
    Environment = "production"
    Architecture = "three-tier"
  }
}
```

### Cost-Optimized VPC

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "cost-optimized-vpc"
  vpc_cidr = "10.4.0.0/16"
  
  # Minimize costs
  max_availability_zones = 2          # Use only 2 AZs
  single_nat_gateway     = true       # Single NAT Gateway
  
  # Only create necessary subnets
  create_public_subnets   = true
  create_private_subnets  = true
  create_database_subnets = false
  
  # Use VPC endpoints to reduce NAT Gateway costs
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  
  # Minimal flow logs
  enable_flow_logs         = true
  flow_logs_traffic_type   = "REJECT"  # Only log rejected traffic
  flow_logs_retention_days = 7
  
  tags = {
    Environment = "development"
    CostOptimized = "true"
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
| vpc_name | Name of the VPC | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| max_availability_zones | Maximum number of AZs to use | `number` | `3` | no |
| create_public_subnets | Create public subnets | `bool` | `true` | no |
| create_private_subnets | Create private subnets | `bool` | `true` | no |
| create_database_subnets | Create database subnets | `bool` | `false` | no |
| create_internet_gateway | Create Internet Gateway | `bool` | `true` | no |
| create_nat_gateway | Create NAT Gateways | `bool` | `true` | no |
| single_nat_gateway | Use single NAT Gateway | `bool` | `false` | no |
| enable_dns_hostnames | Enable DNS hostnames | `bool` | `true` | no |
| enable_dns_support | Enable DNS support | `bool` | `true` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `false` | no |
| enable_s3_endpoint | Enable S3 VPC endpoint | `bool` | `false` | no |
| enable_dynamodb_endpoint | Enable DynamoDB endpoint | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| database_subnet_ids | List of database subnet IDs |
| database_subnet_group_id | ID of database subnet group |
| nat_gateway_ids | List of NAT Gateway IDs |
| nat_gateway_public_ips | List of NAT Gateway public IPs |
| internet_gateway_id | ID of Internet Gateway |
| vpc_summary | Summary of VPC configuration |

## CIDR Planning Guide

### Common VPC CIDR Blocks

| CIDR | Total IPs | Usable IPs | Use Case |
|------|-----------|------------|----------|
| /16 | 65,536 | 65,531 | Large production VPC |
| /20 | 4,096 | 4,091 | Medium VPC |
| /24 | 256 | 251 | Small VPC |

### Subnet Sizing

| Subnet Bits | Subnet Size | IPs per Subnet | Recommended For |
|-------------|-------------|----------------|-----------------|
| 8 | /24 | 256 | Standard subnets |
| 4 | /20 | 4,096 | Large subnets (EKS) |
| 2 | /18 | 16,384 | Very large subnets |

### Example CIDR Calculations

**VPC: 10.0.0.0/16 with 3 AZs and subnet_bits=8**

Public Subnets (/24):
- 10.0.0.0/24 (us-east-1a)
- 10.0.1.0/24 (us-east-1b)
- 10.0.2.0/24 (us-east-1c)

Private Subnets (/24):
- 10.0.3.0/24 (us-east-1a)
- 10.0.4.0/24 (us-east-1b)
- 10.0.5.0/24 (us-east-1c)

Database Subnets (/24):
- 10.0.6.0/24 (us-east-1a)
- 10.0.7.0/24 (us-east-1b)
- 10.0.8.0/24 (us-east-1c)

## Best Practices

### High Availability

1. **Multi-AZ Deployment**: Use at least 3 availability zones
2. **NAT Gateway Redundancy**: Deploy one NAT Gateway per AZ
3. **Subnet Distribution**: Distribute resources across all AZs
4. **Health Checks**: Implement health checks for critical resources

### Security

1. **Private Subnets**: Place application and database tiers in private subnets
2. **Security Groups**: Use security groups for instance-level security
3. **Network ACLs**: Implement NACLs for subnet-level security
4. **Flow Logs**: Enable VPC Flow Logs for audit and troubleshooting
5. **VPC Endpoints**: Use endpoints to avoid internet traffic

### Cost Optimization

1. **Single NAT Gateway**: Use for dev/test environments
2. **VPC Endpoints**: Reduce NAT Gateway data transfer costs
3. **Right-size Subnets**: Don't over-provision IP addresses
4. **Monitor Costs**: Use AWS Cost Explorer to track VPC costs
5. **Delete Unused Resources**: Remove unused NAT Gateways and Elastic IPs

### Performance

1. **Placement Groups**: Use for low-latency requirements
2. **Enhanced Networking**: Enable for high-throughput workloads
3. **VPC Peering**: Use for low-latency cross-VPC communication
4. **Direct Connect**: Consider for hybrid cloud scenarios

## Common Patterns

### Three-Tier Architecture

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name                = "three-tier-vpc"
  vpc_cidr                = "10.0.0.0/16"
  create_public_subnets   = true   # Web tier
  create_private_subnets  = true   # App tier
  create_database_subnets = true   # DB tier
  max_availability_zones  = 3
}
```

### Microservices Architecture

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name               = "microservices-vpc"
  vpc_cidr               = "10.0.0.0/16"
  max_availability_zones = 3
  
  # EKS-specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

### Hybrid Cloud

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = "hybrid-vpc"
  vpc_cidr = "10.0.0.0/16"
  
  # Avoid CIDR conflicts with on-premises
  # Use VPN or Direct Connect
  
  enable_flow_logs = true
}
```

## Troubleshooting

### NAT Gateway Issues

**Problem**: Instances in private subnets can't access internet

**Solutions**:
- Verify NAT Gateway is in public subnet
- Check route table has route to NAT Gateway
- Verify NAT Gateway has Elastic IP
- Check security groups allow outbound traffic

### DNS Resolution Issues

**Problem**: DNS resolution not working

**Solutions**:
- Ensure `enable_dns_support = true`
- Ensure `enable_dns_hostnames = true`
- Check DHCP options set is correct
- Verify security groups allow DNS (port 53)

### Subnet Exhaustion

**Problem**: No more IP addresses available

**Solutions**:
- Increase subnet size (reduce subnet_bits)
- Create additional subnets
- Clean up unused ENIs
- Use secondary CIDR blocks

### VPC Peering Issues

**Problem**: Can't communicate with peered VPC

**Solutions**:
- Check route tables have peering routes
- Verify security groups allow traffic
- Ensure CIDR blocks don't overlap
- Check NACLs allow traffic

## Cost Breakdown

### NAT Gateway Costs (us-east-1)

| Component | Cost |
|-----------|------|
| NAT Gateway (per hour) | $0.045 |
| Data Processing (per GB) | $0.045 |
| Monthly (single NAT) | ~$32.85 |
| Monthly (3 NATs) | ~$98.55 |

### Cost Optimization Tips

1. Use single NAT Gateway for dev/test
2. Use VPC endpoints for S3/DynamoDB
3. Compress data before transfer
4. Use CloudFront for static content
5. Monitor and optimize data transfer

## Migration Guide

### From Default VPC

```bash
# 1. Create new VPC with this module
# 2. Launch new resources in new VPC
# 3. Migrate data
# 4. Update DNS records
# 5. Decommission old resources
```

### From Existing VPC

```bash
# 1. Import existing VPC
terraform import module.vpc.aws_vpc.this vpc-xxxxx

# 2. Import subnets
terraform import module.vpc.aws_subnet.public[0] subnet-xxxxx

# 3. Verify state
terraform plan
```

## License

This module is maintained by the DevOps team and is available under the MIT License.

## Authors

- DevOps Team

## Support

For issues and questions, please contact the DevOps team or create an issue in the repository.
