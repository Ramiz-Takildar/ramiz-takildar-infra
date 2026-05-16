# ============================================================================
# EKS Cluster Module - Variables
# ============================================================================

# ============================================================================
# Cluster Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and can only contain alphanumeric characters and hyphens."
  }
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.cluster_version))
    error_message = "Cluster version must be in format X.Y (e.g., 1.28)."
  }
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from"
  type        = string
  default     = ""
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are ipv4 (default) and ipv6"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "ipv6"], var.cluster_ip_family)
    error_message = "IP family must be either 'ipv4' or 'ipv6'."
  }
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.cluster_enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Invalid log type. Valid values are: api, audit, authenticator, controllerManager, scheduler."
  }
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (vpc-xxxxxxxx)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (must be in at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs for the EKS node groups. If not specified, uses subnet_ids"
  type        = list(string)
  default     = []
}

variable "fargate_subnet_ids" {
  description = "List of subnet IDs for Fargate profiles. Must be private subnets"
  type        = list(string)
  default     = []
}

# ============================================================================
# Encryption Configuration
# ============================================================================

variable "create_kms_key" {
  description = "Create a KMS key for EKS secret encryption"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of existing KMS key to use for EKS secret encryption. Only used if create_kms_key is false"
  type        = string
  default     = ""
}

variable "kms_key_deletion_window" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

# ============================================================================
# CloudWatch Configuration
# ============================================================================

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention must be a valid value."
  }
}

variable "cloudwatch_log_kms_key_id" {
  description = "KMS key ID to encrypt CloudWatch logs"
  type        = string
  default     = null
}

# ============================================================================
# IRSA (IAM Roles for Service Accounts) Configuration
# ============================================================================

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

# ============================================================================
# Node Groups Configuration
# ============================================================================

variable "node_groups" {
  description = <<-EOT
    Map of EKS managed node group definitions to create.
    
    Example:
    {
      general = {
        desired_size = 2
        max_size     = 4
        min_size     = 1
        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"
        disk_size      = 20
        labels = {
          role = "general"
        }
        taints = []
        tags = {}
      }
      spot = {
        desired_size = 2
        max_size     = 10
        min_size     = 0
        instance_types = ["t3.medium", "t3a.medium"]
        capacity_type  = "SPOT"
        disk_size      = 20
        labels = {
          role = "spot"
        }
        taints = [
          {
            key    = "spot"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      }
    }
  EOT
  type        = any
  default     = {}
}

# ============================================================================
# Fargate Profiles Configuration
# ============================================================================

variable "fargate_profiles" {
  description = <<-EOT
    Map of Fargate profile definitions to create.
    
    Example:
    {
      default = {
        selectors = [
          {
            namespace = "default"
            labels = {
              fargate = "true"
            }
          },
          {
            namespace = "kube-system"
          }
        ]
      }
    }
  EOT
  type        = any
  default     = {}
}

# ============================================================================
# Add-ons Configuration
# ============================================================================

variable "cluster_addons" {
  description = <<-EOT
    Map of cluster addon configurations to enable.
    
    Example:
    {
      vpc-cni = {
        addon_version = "v1.15.0-eksbuild.2"
        resolve_conflicts = "OVERWRITE"
      }
      coredns = {
        addon_version = "v1.10.1-eksbuild.2"
        resolve_conflicts = "OVERWRITE"
      }
      kube-proxy = {
        addon_version = "v1.28.1-eksbuild.1"
        resolve_conflicts = "OVERWRITE"
      }
      aws-ebs-csi-driver = {
        addon_version = "v1.24.0-eksbuild.1"
        resolve_conflicts = "OVERWRITE"
        service_account_role_arn = "arn:aws:iam::123456789012:role/AmazonEKS_EBS_CSI_DriverRole"
      }
    }
  EOT
  type        = any
  default = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
  }
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
