terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0, < 5.100.0"
    }
  }

  backend "s3" {
    bucket         = "ramiz-takildar-infra"
    key            = "prod/rds/terraform.tfstate"
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
        Service     = "RDS"
      }
    )
  }
}

# RDS Module
module "rds" {
  source = "../../../modules/rds"

  # Database Configuration
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  environment    = var.environment

  # Storage Configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Database Configuration
  db_name                     = var.db_name
  username                    = var.username
  manage_master_user_password = var.manage_master_user_password

  # Network Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Security
  create_security_group      = var.create_security_group
  allowed_security_group_ids = var.allowed_security_group_ids
  allowed_cidr_blocks        = var.allowed_cidr_blocks
  publicly_accessible        = var.publicly_accessible

  # High Availability
  multi_az = var.multi_az

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  skip_final_snapshot     = var.skip_final_snapshot

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Parameter Group
  create_db_parameter_group = var.create_db_parameter_group
  parameter_group_family    = var.parameter_group_family
  parameters                = var.parameters

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # CloudWatch Alarms
  create_cloudwatch_alarms = var.create_cloudwatch_alarms
  alarm_actions            = var.alarm_actions

  # Read Replicas
  create_read_replica = var.create_read_replica
  read_replica_count  = var.read_replica_count

  # IAM Authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Secrets Manager
  create_db_credentials_secret = var.create_db_credentials_secret

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Tags
  tags = var.tags
}
