# ============================================================================
# EC2 Instance Module - Variables
# ============================================================================
# This file defines all input variables for the EC2 module.
# Variables are organized by category for better readability.
# ============================================================================

# ============================================================================
# General Configuration
# ============================================================================

variable "instance_name" {
  description = "Name prefix for EC2 instances"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.instance_name))
    error_message = "Instance name must contain only alphanumeric characters and hyphens."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Instance Configuration
# ============================================================================

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type (e.g., t3.micro, m5.large)."
  }
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If not provided, will use the latest AMI based on ami_name_filter"
  type        = string
  default     = ""
}

variable "ami_name_filter" {
  description = "Name filter to find the latest AMI"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
}

variable "ami_owner" {
  description = "Owner ID for AMI filter"
  type        = string
  default     = "099720109477" # Canonical (Ubuntu)
}

variable "architecture" {
  description = "Architecture for AMI filter"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "Architecture must be either x86_64 or arm64."
  }
}

variable "tenancy" {
  description = "Tenancy of the instance (default, dedicated, host)"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy must be one of: default, dedicated, host."
  }
}

variable "hibernation" {
  description = "Enable hibernation for the instance"
  type        = bool
  default     = false
}

variable "disable_api_termination" {
  description = "Enable EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance (stop, terminate)"
  type        = string
  default     = "stop"

  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "Shutdown behavior must be either stop or terminate."
  }
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance"
  type        = bool
  default     = true
}

variable "cpu_credits" {
  description = "Credit option for CPU usage (unlimited, standard)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["unlimited", "standard"], var.cpu_credits)
    error_message = "CPU credits must be either unlimited or standard."
  }
}

variable "capacity_reservation_id" {
  description = "ID of the capacity reservation to use"
  type        = string
  default     = ""
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "vpc_id" {
  description = "VPC ID where security group will be created"
  type        = string
  default     = ""
}

variable "associate_public_ip_address" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = false
}

variable "allocate_eip" {
  description = "Allocate and associate Elastic IP with instances"
  type        = bool
  default     = false
}

# ============================================================================
# Security Group Configuration
# ============================================================================

variable "create_security_group" {
  description = "Create a new security group for the instances"
  type        = bool
  default     = true
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instances (used when create_security_group is false)"
  type        = list(string)
  default     = []
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    description      = optional(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    }
  ]
}

variable "egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port        = number
    to_port          = number
    protocol         = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    description      = optional(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound traffic"
    }
  ]
}

# ============================================================================
# SSH Key Pair Configuration
# ============================================================================

variable "create_key_pair" {
  description = "Create a new SSH key pair"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name of the SSH key pair to use or create"
  type        = string
  default     = ""
}

variable "public_key" {
  description = "Public key material for SSH key pair (required if create_key_pair is true)"
  type        = string
  default     = ""
}

# ============================================================================
# Storage Configuration
# ============================================================================

variable "root_volume_type" {
  description = "Type of root volume (gp2, gp3, io1, io2, standard)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "standard"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp2, gp3, io1, io2, standard."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "root_volume_iops" {
  description = "IOPS for root volume (only for io1/io2 volumes)"
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  description = "Throughput for root volume in MB/s (only for gp3 volumes)"
  type        = number
  default     = null
}

variable "root_volume_encrypted" {
  description = "Enable encryption for root volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS key ID for root volume encryption"
  type        = string
  default     = null
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "ebs_block_devices" {
  description = "Additional EBS block devices to attach to the instance"
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = optional(string)
    iops                  = optional(number)
    throughput            = optional(number)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    delete_on_termination = optional(bool)
    snapshot_id           = optional(string)
  }))
  default = []
}

# ============================================================================
# User Data Configuration
# ============================================================================

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "user_data_base64" {
  description = "Base64-encoded user data script"
  type        = string
  default     = ""
}

# ============================================================================
# IAM Configuration
# ============================================================================

variable "create_iam_instance_profile" {
  description = "Create IAM instance profile for the instances"
  type        = bool
  default     = false
}

variable "iam_instance_profile_name" {
  description = "Name of existing IAM instance profile to attach (used when create_iam_instance_profile is false)"
  type        = string
  default     = ""
}

variable "iam_managed_policy_arns" {
  description = "List of IAM managed policy ARNs to attach to the instance role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

variable "iam_custom_policy" {
  description = "Custom IAM policy JSON to attach to the instance role"
  type        = string
  default     = ""
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for the instances"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold >= 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 0 and 100."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# ============================================================================
# Metadata Configuration
# ============================================================================

variable "metadata_http_tokens" {
  description = "Whether or not the metadata service requires session tokens (IMDSv2)"
  type        = string
  default     = "required"

  validation {
    condition     = contains(["optional", "required"], var.metadata_http_tokens)
    error_message = "Metadata HTTP tokens must be either optional or required."
  }
}

variable "metadata_http_put_response_hop_limit" {
  description = "Desired HTTP PUT response hop limit for instance metadata requests"
  type        = number
  default     = 1

  validation {
    condition     = var.metadata_http_put_response_hop_limit >= 1 && var.metadata_http_put_response_hop_limit <= 64
    error_message = "Metadata HTTP PUT response hop limit must be between 1 and 64."
  }
}

variable "enable_instance_metadata_tags" {
  description = "Enable access to instance tags from the instance metadata"
  type        = bool
  default     = false
}

# ============================================================================
# Variable Usage Examples
# ============================================================================
#
# Basic Usage:
# ------------
# instance_name = "web-server"
# instance_type = "t3.micro"
# instance_count = 2
# subnet_ids = ["subnet-12345678", "subnet-87654321"]
#
# With Custom AMI:
# ----------------
# ami_name_filter = "amzn2-ami-hvm-*-x86_64-gp2"
# ami_owner = "137112412989" # Amazon
#
# With Security Group:
# --------------------
# create_security_group = true
# vpc_id = "vpc-12345678"
# ingress_rules = [
#   {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTP access"
#   },
#   {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTPS access"
#   }
# ]
#
# With Additional EBS Volumes:
# ----------------------------
# ebs_block_devices = [
#   {
#     device_name = "/dev/sdf"
#     volume_size = 100
#     volume_type = "gp3"
#     encrypted   = true
#   }
# ]
#
# With IAM Role:
# --------------
# create_iam_instance_profile = true
# iam_managed_policy_arns = [
#   "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#   "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
# ]
#
# ============================================================================
