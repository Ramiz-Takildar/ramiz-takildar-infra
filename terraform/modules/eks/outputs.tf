# ============================================================================
# EKS Cluster Module - Outputs
# ============================================================================

# ============================================================================
# Cluster Outputs
# ============================================================================

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of CREATING, ACTIVE, DELETING, FAILED"
  value       = aws_eks_cluster.this.status
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
}

output "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by the EKS cluster on 1.14 or later"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

# ============================================================================
# IAM Role Outputs
# ============================================================================

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = aws_iam_role.node_group.name
}

output "fargate_iam_role_arn" {
  description = "IAM role ARN of the EKS Fargate profiles"
  value       = try(aws_iam_role.fargate[0].arn, null)
}

output "fargate_iam_role_name" {
  description = "IAM role name of the EKS Fargate profiles"
  value       = try(aws_iam_role.fargate[0].name, null)
}

# ============================================================================
# OIDC Provider Outputs
# ============================================================================

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (without https://)"
  value       = try(replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", ""), null)
}

# ============================================================================
# Node Group Outputs
# ============================================================================

output "node_groups" {
  description = "Map of attribute maps for all EKS node groups created"
  value = {
    for k, v in aws_eks_node_group.this : k => {
      id                = v.id
      arn               = v.arn
      status            = v.status
      capacity_type     = v.capacity_type
      instance_types    = v.instance_types
      node_group_name   = v.node_group_name
      resources         = v.resources
      remote_access     = v.remote_access
      scaling_config    = v.scaling_config
      update_config     = v.update_config
      version           = v.version
    }
  }
}

output "node_group_ids" {
  description = "List of all node group IDs"
  value       = [for ng in aws_eks_node_group.this : ng.id]
}

output "node_group_arns" {
  description = "List of all node group ARNs"
  value       = [for ng in aws_eks_node_group.this : ng.arn]
}

output "node_group_statuses" {
  description = "Map of node group names to their status"
  value       = { for k, v in aws_eks_node_group.this : k => v.status }
}

# ============================================================================
# Fargate Profile Outputs
# ============================================================================

output "fargate_profiles" {
  description = "Map of attribute maps for all EKS Fargate profiles created"
  value = {
    for k, v in aws_eks_fargate_profile.this : k => {
      id                   = v.id
      arn                  = v.arn
      status               = v.status
      fargate_profile_name = v.fargate_profile_name
    }
  }
}

output "fargate_profile_ids" {
  description = "List of all Fargate profile IDs"
  value       = [for fp in aws_eks_fargate_profile.this : fp.id]
}

output "fargate_profile_arns" {
  description = "List of all Fargate profile ARNs"
  value       = [for fp in aws_eks_fargate_profile.this : fp.arn]
}

# ============================================================================
# Add-on Outputs
# ============================================================================

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value = {
    for k, v in aws_eks_addon.this : k => {
      id            = v.id
      arn           = v.arn
      addon_name    = v.addon_name
      addon_version = v.addon_version
    }
  }
}

# ============================================================================
# KMS Key Outputs
# ============================================================================

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = try(aws_kms_key.eks[0].id, null)
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = try(aws_kms_key.eks[0].arn, null)
}

# ============================================================================
# CloudWatch Outputs
# ============================================================================

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.cluster.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for EKS cluster logs"
  value       = aws_cloudwatch_log_group.cluster.arn
}

# ============================================================================
# Kubeconfig Output
# ============================================================================

output "kubeconfig" {
  description = "kubectl config as generated by the module"
  value = {
    cluster_name                   = aws_eks_cluster.this.id
    endpoint                       = aws_eks_cluster.this.endpoint
    cluster_ca_certificate         = aws_eks_cluster.this.certificate_authority[0].data
    token                          = data.aws_eks_cluster_auth.this.token
    oidc_issuer_url               = try(aws_eks_cluster.this.identity[0].oidc[0].issuer, null)
  }
  sensitive = true
}

# ============================================================================
# Connection Command Output
# ============================================================================

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.this.id}"
}
