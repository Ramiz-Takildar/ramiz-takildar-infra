# ============================================================================
# RDS Database Module - Main Configuration
# ============================================================================
# This module creates an Amazon RDS database instance with enterprise features:
# - Multiple database engines (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server)
# - Multi-AZ deployment for high availability
# - Read replicas for scaling
# - Automated backups and snapshots
# - Encryption at rest and in transit
# - Enhanced monitoring
# - Performance Insights
# - Parameter groups and option groups
# - Security groups
# - Subnet groups
# - CloudWatch alarms
# - IAM database authentication
# - Secrets Manager integration
#
# High Availability:
# - Multi-AZ deployment
# - Automated failover
# - Read replicas
# - Automated backups
# ============================================================================

# ============================================================================
# Data Sources
# ============================================================================

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  identifier = var.identifier
  
  # Database port based on engine
  port = var.port != null ? var.port : (
    var.engine == "postgres" ? 5432 :
    var.engine == "mysql" ? 3306 :
    var.engine == "mariadb" ? 3306 :
    var.engine == "oracle-ee" || var.engine == "oracle-se2" ? 1521 :
    var.engine == "sqlserver-ee" || var.engine == "sqlserver-se" || var.engine == "sqlserver-ex" || var.engine == "sqlserver-web" ? 1433 :
    3306
  )
  
  # Common tags
  common_tags = merge(
    var.tags,
    {
      Name = local.identifier
    }
  )
  
  # Create final snapshot name
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}

# ============================================================================
# KMS Key for Encryption
# ============================================================================

resource "aws_kms_key" "rds" {
  count = var.create_kms_key ? 1 : 0

  description             = "RDS encryption key for ${local.identifier}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-rds-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.identifier}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

# ============================================================================
# DB Subnet Group
# ============================================================================

resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = "${local.identifier}-subnet-group"
  description = "Database subnet group for ${local.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-subnet-group"
    }
  )
}

# ============================================================================
# Security Group for RDS
# ============================================================================

resource "aws_security_group" "rds" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.identifier}-rds-sg"
  description = "Security group for RDS instance ${local.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-rds-sg"
    }
  )
}

resource "aws_security_group_rule" "rds_ingress" {
  count = var.create_security_group ? length(var.allowed_security_group_ids) : 0

  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.rds[0].id
  description              = "Allow database access from security group"
}

resource "aws_security_group_rule" "rds_ingress_cidr" {
  count = var.create_security_group && length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.rds[0].id
  description       = "Allow database access from CIDR blocks"
}

resource "aws_security_group_rule" "rds_egress" {
  count = var.create_security_group ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds[0].id
  description       = "Allow all outbound traffic"
}

# ============================================================================
# DB Parameter Group
# ============================================================================

resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0

  name        = "${local.identifier}-params"
  family      = var.parameter_group_family
  description = "Database parameter group for ${local.identifier}"

  dynamic "parameter" {
    for_each = var.parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# DB Option Group
# ============================================================================

resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0

  name                     = "${local.identifier}-options"
  option_group_description = "Database option group for ${local.identifier}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options

    content {
      option_name = option.value.option_name
      port        = lookup(option.value, "port", null)
      version     = lookup(option.value, "version", null)
      db_security_group_memberships = lookup(option.value, "db_security_group_memberships", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])

        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# IAM Role for Enhanced Monitoring
# ============================================================================

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  name               = "${local.identifier}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.enabled_cloudwatch_logs_exports != null || var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================================
# Random Password for Master User
# ============================================================================

resource "random_password" "master_password" {
  count = var.manage_master_user_password && var.master_password == null ? 1 : 0

  length  = var.master_password_length
  special = true
}

# ============================================================================
# Secrets Manager Secret for Database Credentials
# ============================================================================

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.create_db_credentials_secret ? 1 : 0

  name        = "${local.identifier}-db-credentials"
  description = "Database credentials for ${local.identifier}"
  kms_key_id  = var.create_kms_key ? aws_kms_key.rds[0].id : var.kms_key_id

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count = var.create_db_credentials_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = var.username
    password = var.manage_master_user_password ? (var.master_password != null ? var.master_password : random_password.master_password[0].result) : var.master_password
    engine   = var.engine
    host     = aws_db_instance.this.address
    port     = local.port
    dbname   = var.db_name
  })

  depends_on = [aws_db_instance.this]
}

# ============================================================================
# RDS Database Instance
# ============================================================================

resource "aws_db_instance" "this" {
  identifier = local.identifier

  # Engine configuration
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id           = var.storage_encrypted ? (var.create_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_id) : null
  iops                 = var.iops
  storage_throughput   = var.storage_throughput

  # Database configuration
  db_name  = var.db_name
  username = var.username
  password = var.manage_master_user_password ? (var.master_password != null ? var.master_password : random_password.master_password[0].result) : var.master_password
  port     = local.port

  # Network configuration
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.rds[0].id] : var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  # High availability
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : var.availability_zone

  # Backup configuration
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier
  snapshot_identifier       = var.snapshot_identifier

  # Maintenance
  maintenance_window              = var.maintenance_window
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  apply_immediately               = var.apply_immediately

  # Parameter and option groups
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled && var.performance_insights_kms_key_id != null ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # IAM database authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Deletion protection
  deletion_protection = var.deletion_protection

  # Character set
  character_set_name = var.character_set_name

  # License model
  license_model = var.license_model

  # Timezone
  timezone = var.timezone

  # Domain
  domain               = var.domain
  domain_iam_role_name = var.domain_iam_role_name

  # Replica configuration
  replicate_source_db = var.replicate_source_db

  # Blue/Green deployment
  blue_green_update {
    enabled = var.blue_green_update_enabled
  }

  tags = local.common_tags

  timeouts {
    create = lookup(var.timeouts, "create", "40m")
    update = lookup(var.timeouts, "update", "80m")
    delete = lookup(var.timeouts, "delete", "60m")
  }

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      password,
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.enhanced_monitoring,
  ]
}

# ============================================================================
# Read Replicas
# ============================================================================

resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? var.read_replica_count : 0

  identifier = "${local.identifier}-replica-${count.index + 1}"

  # Replica configuration
  replicate_source_db = aws_db_instance.this.identifier

  # Instance configuration
  instance_class        = var.read_replica_instance_class != null ? var.read_replica_instance_class : var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.storage_encrypted ? (var.create_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_id) : null
  iops                  = var.iops
  storage_throughput    = var.storage_throughput

  # Network configuration
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.rds[0].id] : var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.read_replica_multi_az ? null : element(var.read_replica_availability_zones, count.index)
  multi_az               = var.read_replica_multi_az

  # Backup configuration
  backup_retention_period = 0 # Read replicas don't need backups
  skip_final_snapshot     = true

  # Maintenance
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Parameter group
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled && var.performance_insights_kms_key_id != null ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # IAM database authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Deletion protection
  deletion_protection = var.deletion_protection

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-replica-${count.index + 1}"
      Role = "read-replica"
    }
  )

  timeouts {
    create = lookup(var.timeouts, "create", "40m")
    update = lookup(var.timeouts, "update", "80m")
    delete = lookup(var.timeouts, "delete", "60m")
  }

  depends_on = [aws_db_instance.this]
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.identifier}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "disk_queue_depth" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.identifier}-disk-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_queue_depth_threshold
  alarm_description   = "This metric monitors RDS disk queue depth"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.identifier}-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.freeable_memory_threshold
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.identifier}-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.free_storage_space_threshold
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = local.common_tags
}

# ============================================================================
# Outputs
# ============================================================================
# Outputs are defined in outputs.tf
# ============================================================================
