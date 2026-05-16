terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket         = "ramiz-takildar-infra"
    key            = "prod/ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = "prod"
        ManagedBy   = "Terraform"
        Service     = "EC2"
      }
    )
  }
}

# Data source for latest AMI
data "aws_ami" "selected" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# EC2 Module
module "ec2" {
  source = "../../../modules/ec2"

  # Instance Configuration
  instance_name  = var.instance_name
  instance_type  = var.instance_type
  instance_count = var.instance_count

  # AMI Configuration
  ami_id = data.aws_ami.selected.id

  # Network Configuration
  vpc_id                      = var.vpc_id
  subnet_ids                  = var.subnet_ids
  associate_public_ip_address = var.associate_public_ip_address

  # Storage Configuration
  root_volume_size      = var.root_volume_size
  root_volume_type      = var.root_volume_type
  root_volume_encrypted = var.root_volume_encrypted

  # Security
  create_security_group      = var.create_security_group
  security_group_name        = "${var.instance_name}-sg"
  security_group_description = "Security group for ${var.instance_name}"
  ingress_rules              = var.ingress_rules
  egress_rules               = var.egress_rules

  # Monitoring
  enable_detailed_monitoring = var.enable_detailed_monitoring

  # IAM
  create_iam_instance_profile = var.create_iam_instance_profile
  iam_role_name               = var.iam_role_name
  iam_role_policies           = var.iam_role_policies

  # User Data
  user_data = var.user_data

  # Key Pair
  key_name = var.key_name

  # Tags
  tags = var.tags
}
