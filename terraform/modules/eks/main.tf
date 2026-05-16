# ============================================================================
# EKS Cluster Module - Main Configuration
# ============================================================================
# This module creates an Amazon EKS cluster with enterprise-grade features:
# - EKS Control Plane
# - Managed Node Groups
# - Fargate Profiles (optional)
# - OIDC Provider for IRSA
# - Cluster Add-ons
# - Security Groups
# - IAM Roles and Policies
# - CloudWatch Logging
# - Encryption
# - VPC CNI configuration
#
# High Availability:
# - Multi-AZ node groups
# - Auto-scaling
# - Pod disruption budgets
# ============================================================================

# ============================================================================
# Data Sources
# ============================================================================

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get EKS cluster authentication token
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  cluster_name = var.cluster_name
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
  )
  
  # Node group tags
  node_group_tags = merge(
    local.common_tags,
    {
      "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"               = "true"
    }
  )
}

# ============================================================================
# KMS Key for Encryption
# ============================================================================

resource "aws_kms_key" "eks" {
  count = var.create_kms_key ? 1 : 0

  description             = "EKS Secret Encryption Key for ${local.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-eks-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# ============================================================================
# IAM Role for EKS Cluster
# ============================================================================

resource "aws_iam_role" "cluster" {
  name               = "${local.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ============================================================================
# Security Group for EKS Cluster
# ============================================================================

resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-cluster-sg"
    }
  )
}

resource "aws_security_group_rule" "cluster_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
}

resource "aws_security_group_rule" "cluster_ingress_workstation_https" {
  count = length(var.cluster_endpoint_public_access_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.cluster_endpoint_public_access_cidrs
  security_group_id = aws_security_group.cluster.id
  description       = "Allow workstation to communicate with the cluster API Server"
}

# ============================================================================
# EKS Cluster
# ============================================================================

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # Encryption configuration
  dynamic "encryption_config" {
    for_each = var.create_kms_key || var.kms_key_arn != "" ? [1] : []

    content {
      provider {
        key_arn = var.create_kms_key ? aws_kms_key.eks[0].arn : var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  # Enable control plane logging
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Kubernetes network configuration
  dynamic "kubernetes_network_config" {
    for_each = var.cluster_service_ipv4_cidr != "" ? [1] : []

    content {
      service_ipv4_cidr = var.cluster_service_ipv4_cidr
      ip_family         = var.cluster_ip_family
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.cluster,
  ]
}

# ============================================================================
# CloudWatch Log Group for EKS
# ============================================================================

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.cloudwatch_log_kms_key_id

  tags = local.common_tags
}

# ============================================================================
# OIDC Provider for IRSA
# ============================================================================

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = local.common_tags
}

data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ============================================================================
# IAM Role for Node Groups
# ============================================================================

resource "aws_iam_role" "node_group" {
  name               = "${local.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "node_group_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# ============================================================================
# EKS Managed Node Groups
# ============================================================================

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.node_group_subnet_ids
  version         = lookup(each.value, "version", var.cluster_version)

  scaling_config {
    desired_size = lookup(each.value, "desired_size", 2)
    max_size     = lookup(each.value, "max_size", 4)
    min_size     = lookup(each.value, "min_size", 1)
  }

  update_config {
    max_unavailable_percentage = lookup(each.value, "max_unavailable_percentage", 33)
  }

  # Instance types
  instance_types = lookup(each.value, "instance_types", ["t3.medium"])
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size      = lookup(each.value, "disk_size", 20)

  # Launch template
  dynamic "launch_template" {
    for_each = lookup(each.value, "launch_template_id", null) != null ? [1] : []

    content {
      id      = lookup(each.value, "launch_template_id", null)
      version = lookup(each.value, "launch_template_version", "$Latest")
    }
  }

  # Remote access
  dynamic "remote_access" {
    for_each = lookup(each.value, "key_name", null) != null ? [1] : []

    content {
      ec2_ssh_key               = lookup(each.value, "key_name", null)
      source_security_group_ids = lookup(each.value, "source_security_group_ids", null)
    }
  }

  # Taints
  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])

    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value", null)
      effect = taint.value.effect
    }
  }

  labels = merge(
    lookup(each.value, "labels", {}),
    {
      "node-group" = each.key
    }
  )

  tags = merge(
    local.node_group_tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${local.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# ============================================================================
# EKS Add-ons
# ============================================================================

resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name             = aws_eks_cluster.this.name
  addon_name               = each.key
  addon_version            = lookup(each.value, "addon_version", null)
  resolve_conflicts        = lookup(each.value, "resolve_conflicts", "OVERWRITE")
  service_account_role_arn = lookup(each.value, "service_account_role_arn", null)

  tags = local.common_tags

  depends_on = [
    aws_eks_node_group.this,
  ]
}

# ============================================================================
# Fargate Profile (Optional)
# ============================================================================

resource "aws_iam_role" "fargate" {
  count = length(var.fargate_profiles) > 0 ? 1 : 0

  name               = "${local.cluster_name}-fargate-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "fargate_assume_role" {
  count = length(var.fargate_profiles) > 0 ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "fargate_AmazonEKSFargatePodExecutionRolePolicy" {
  count = length(var.fargate_profiles) > 0 ? 1 : 0

  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate[0].name
}

resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name           = aws_eks_cluster.this.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.fargate[0].arn
  subnet_ids             = var.fargate_subnet_ids

  dynamic "selector" {
    for_each = lookup(each.value, "selectors", [])

    content {
      namespace = selector.value.namespace
      labels    = lookup(selector.value, "labels", {})
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.fargate_AmazonEKSFargatePodExecutionRolePolicy,
  ]
}

# ============================================================================
# AWS Auth ConfigMap (for additional IAM users/roles)
# ============================================================================

# Note: This is typically managed by kubectl or Terraform Kubernetes provider
# Placeholder for documentation purposes

# ============================================================================
# Outputs
# ============================================================================
# Outputs are defined in outputs.tf
# ============================================================================
