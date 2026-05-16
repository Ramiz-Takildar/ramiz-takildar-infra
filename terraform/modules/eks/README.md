# EKS Cluster Terraform Module

This module creates a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with enterprise-grade features including managed node groups, Fargate profiles, OIDC provider for IRSA, cluster add-ons, and comprehensive security configurations.

## Features

- **EKS Control Plane**: Fully managed Kubernetes control plane
- **Managed Node Groups**: Auto-scaling EC2 node groups with support for multiple instance types
- **Fargate Profiles**: Serverless compute for Kubernetes pods
- **IRSA Support**: IAM Roles for Service Accounts via OIDC provider
- **Cluster Add-ons**: VPC CNI, CoreDNS, kube-proxy, EBS CSI driver
- **Security**: KMS encryption, security groups, IAM roles with least privilege
- **High Availability**: Multi-AZ deployment support
- **Logging**: CloudWatch integration for control plane logs
- **Monitoring**: CloudWatch metrics and alarms
- **Tagging**: Comprehensive tagging for cost allocation and resource management

## Usage

### Basic Example

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]

  node_groups = {
    general = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
    }
  }

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Advanced Example with Multiple Node Groups and Fargate

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "production-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Control plane access
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]

  # Enable all control plane logs
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # KMS encryption
  create_kms_key = true

  # IRSA
  enable_irsa = true

  # Multiple node groups
  node_groups = {
    # General purpose on-demand nodes
    general = {
      desired_size   = 3
      max_size       = 6
      min_size       = 2
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      labels = {
        role = "general"
        tier = "application"
      }
    }

    # Spot instances for non-critical workloads
    spot = {
      desired_size   = 2
      max_size       = 10
      min_size       = 0
      instance_types = ["t3.large", "t3a.large", "t2.large"]
      capacity_type  = "SPOT"
      disk_size      = 50
      labels = {
        role = "spot"
        tier = "batch"
      }
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
    }

    # GPU nodes for ML workloads
    gpu = {
      desired_size   = 1
      max_size       = 3
      min_size       = 0
      instance_types = ["g4dn.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        role        = "gpu"
        tier        = "ml"
        nvidia.com/gpu = "true"
      }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NoSchedule"
        }
      ]
    }
  }

  # Fargate profiles for serverless workloads
  fargate_profiles = {
    default = {
      selectors = [
        {
          namespace = "default"
          labels = {
            fargate = "true"
          }
        }
      ]
    }
    kube-system = {
      selectors = [
        {
          namespace = "kube-system"
        }
      ]
    }
  }

  fargate_subnet_ids = module.vpc.private_subnet_ids

  # Cluster add-ons
  cluster_addons = {
    vpc-cni = {
      addon_version     = "v1.15.0-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      addon_version     = "v1.10.1-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.28.1-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      addon_version            = "v1.24.0-eksbuild.1"
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  # CloudWatch configuration
  cloudwatch_log_retention_days = 90

  tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

### Example with Custom Launch Template

```hcl
# Create launch template
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "eks-nodes-"
  
  block_device_mappings {
    device_name = "/dev/xvda"
    
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    custom = {
      desired_size          = 2
      max_size              = 4
      min_size              = 1
      instance_types        = ["t3.large"]
      launch_template_id    = aws_launch_template.eks_nodes.id
      launch_template_version = "$Latest"
    }
  }

  tags = {
    Environment = "dev"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| tls | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | VPC ID where the cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the EKS cluster (must be in at least 2 AZs) | `list(string)` | n/a | yes |
| cluster_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| cluster_endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| cluster_endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| cluster_endpoint_public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| cluster_service_ipv4_cidr | The CIDR block to assign Kubernetes service IP addresses from | `string` | `""` | no |
| cluster_ip_family | The IP family used to assign Kubernetes pod and service addresses | `string` | `"ipv4"` | no |
| cluster_enabled_log_types | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | no |
| node_group_subnet_ids | List of subnet IDs for the EKS node groups | `list(string)` | `[]` | no |
| fargate_subnet_ids | List of subnet IDs for Fargate profiles | `list(string)` | `[]` | no |
| create_kms_key | Create a KMS key for EKS secret encryption | `bool` | `true` | no |
| kms_key_arn | ARN of existing KMS key to use for EKS secret encryption | `string` | `""` | no |
| kms_key_deletion_window | Duration in days after which the key is deleted | `number` | `30` | no |
| cloudwatch_log_retention_days | Number of days to retain CloudWatch logs | `number` | `90` | no |
| cloudwatch_log_kms_key_id | KMS key ID to encrypt CloudWatch logs | `string` | `null` | no |
| enable_irsa | Enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| node_groups | Map of EKS managed node group definitions | `any` | `{}` | no |
| fargate_profiles | Map of Fargate profile definitions | `any` | `{}` | no |
| cluster_addons | Map of cluster addon configurations | `any` | See variables.tf | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_version | The Kubernetes server version for the cluster |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_certificate_authority_data | Base64 encoded certificate data |
| cluster_oidc_issuer_url | The URL on the EKS cluster OIDC Issuer |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| node_group_iam_role_arn | IAM role ARN of the EKS node groups |
| oidc_provider_arn | ARN of the OIDC Provider for EKS |
| oidc_provider | The OpenID Connect identity provider |
| node_groups | Map of all EKS node groups created |
| fargate_profiles | Map of all EKS Fargate profiles created |
| cluster_addons | Map of all EKS cluster addons enabled |
| kms_key_arn | The ARN of the KMS key |
| cloudwatch_log_group_name | Name of the CloudWatch log group |
| configure_kubectl | Command to configure kubectl |

## Post-Deployment Steps

### 1. Configure kubectl

After the cluster is created, configure kubectl to connect to your cluster:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

Or use the output from the module:

```bash
$(terraform output -raw configure_kubectl)
```

### 2. Verify Cluster Access

```bash
kubectl get nodes
kubectl get pods -A
```

### 3. Install Additional Tools (Optional)

#### AWS Load Balancer Controller

```bash
# Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# Install using Helm
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<role-arn>
```

#### Cluster Autoscaler

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

#### Metrics Server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Security Best Practices

1. **Network Security**
   - Use private subnets for node groups
   - Restrict public API access to specific CIDR blocks
   - Enable private endpoint access

2. **Encryption**
   - Enable KMS encryption for secrets
   - Use encrypted EBS volumes
   - Enable CloudWatch log encryption

3. **IAM**
   - Use IRSA for pod-level IAM permissions
   - Follow least privilege principle
   - Regularly audit IAM roles and policies

4. **Logging and Monitoring**
   - Enable all control plane logs
   - Set up CloudWatch alarms
   - Use Container Insights

5. **Updates**
   - Keep cluster version up to date
   - Update node groups regularly
   - Keep add-ons updated

## Troubleshooting

### Nodes Not Joining Cluster

1. Check security groups allow communication
2. Verify IAM role has correct policies
3. Check subnet routing and NAT gateway
4. Review CloudWatch logs

### Pod Networking Issues

1. Verify VPC CNI add-on is installed
2. Check security group rules
3. Verify subnet has available IPs
4. Review VPC CNI logs

### IRSA Not Working

1. Verify OIDC provider is created
2. Check service account annotations
3. Verify IAM role trust policy
4. Review pod logs for authentication errors

## Examples

See the `examples/` directory for complete working examples:

- `examples/basic/` - Basic EKS cluster
- `examples/advanced/` - Advanced multi-node group setup
- `examples/fargate/` - Fargate-only cluster
- `examples/gpu/` - GPU-enabled node groups

## License

MIT

## Authors

Created and maintained by DevOps Team

## References

- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
