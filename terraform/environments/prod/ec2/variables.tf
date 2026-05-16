variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name prefix for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10"
  }
}

variable "ami_name_filter" {
  description = "AMI name filter pattern"
  type        = string
}

variable "ami_owner" {
  description = "AMI owner ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where instances will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for instance placement"
  type        = list(string)
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "root_volume_size must be between 8 and 1000 GB"
  }
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_type must be one of: gp2, gp3, io1, io2"
  }
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "create_security_group" {
  description = "Whether to create a security group"
  type        = bool
  default     = true
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
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

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "create_iam_instance_profile" {
  description = "Whether to create an IAM instance profile"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = ""
}

variable "iam_role_policies" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
