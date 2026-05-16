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
    key            = "dev/s3/terraform.tfstate"
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
        Environment = "dev"
        ManagedBy   = "Terraform"
        Service     = "S3"
      }
    )
  }
}

# S3 Module
module "s3" {
  source = "../../../modules/s3"

  # Bucket Configuration
  bucket_name        = var.bucket_name
  bucket_name_prefix = var.bucket_name_prefix

  # Versioning
  enable_versioning = var.enable_versioning

  # Encryption
  kms_master_key_id = var.kms_master_key_id

  # Public Access Block
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  # Logging
  enable_logging        = var.enable_logging
  logging_target_bucket = var.logging_target_bucket
  logging_target_prefix = var.logging_target_prefix

  # Lifecycle Rules
  lifecycle_rules = var.lifecycle_rules

  # Intelligent Tiering
  enable_intelligent_tiering = var.enable_intelligent_tiering

  # SSL Enforcement
  enforce_ssl = var.enforce_ssl

  # CORS Configuration
  cors_rules = var.cors_rules

  # Website Configuration
  website_configuration = var.website_configuration

  # Replication
  replication_configuration = var.replication_configuration

  # Object Lock
  object_lock_enabled = var.object_lock_enabled

  # Tags
  tags = var.tags
}
