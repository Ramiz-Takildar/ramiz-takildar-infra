# ============================================================================
# RDS Database Module - Outputs
# ============================================================================

# ============================================================================
# Database Instance Outputs
# ============================================================================

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.this.hosted_zone_id
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_availability_zone" {
  description = "The availability zone of the instance"
  value       = aws_db_instance.this.availability_zone
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = aws_db_instance.this.multi_az
}

output "db_instance_backup_retention_period" {
  description = "The backup retention period"
  value       = aws_db_instance.this.backup_retention_period
}

output "db_instance_backup_window" {
  description = "The backup window"
  value       = aws_db_instance.this.backup_window
}

output "db_instance_maintenance_window" {
  description = "The instance maintenance window"
  value       = aws_db_instance.this.maintenance_window
}

output "db_instance_latest_restorable_time" {
  description = "The latest time to which a database can be restored with point-in-time restore"
  value       = aws_db_instance.this.latest_restorable_time
}

# ============================================================================
# Security Group Outputs
# ============================================================================

output "security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = try(aws_security_group.rds[0].id, null)
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.rds[0].arn, null)
}

output "security_group_name" {
  description = "The name of the security group"
  value       = try(aws_security_group.rds[0].name, null)
}

# ============================================================================
# Subnet Group Outputs
# ============================================================================

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = try(aws_db_subnet_group.this[0].id, null)
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = try(aws_db_subnet_group.this[0].arn, null)
}

# ============================================================================
# Parameter Group Outputs
# ============================================================================

output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = try(aws_db_parameter_group.this[0].id, null)
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = try(aws_db_parameter_group.this[0].arn, null)
}

# ============================================================================
# Option Group Outputs
# ============================================================================

output "db_option_group_id" {
  description = "The db option group id"
  value       = try(aws_db_option_group.this[0].id, null)
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = try(aws_db_option_group.this[0].arn, null)
}

# ============================================================================
# KMS Key Outputs
# ============================================================================

output "kms_key_id" {
  description = "The globally unique identifier for the KMS key"
  value       = try(aws_kms_key.rds[0].id, null)
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key"
  value       = try(aws_kms_key.rds[0].arn, null)
}

# ============================================================================
# IAM Role Outputs
# ============================================================================

output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = try(aws_iam_role.enhanced_monitoring[0].arn, null)
}

output "enhanced_monitoring_iam_role_name" {
  description = "The name of the monitoring role"
  value       = try(aws_iam_role.enhanced_monitoring[0].name, null)
}

# ============================================================================
# Secrets Manager Outputs
# ============================================================================

output "db_credentials_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database credentials"
  value       = try(aws_secretsmanager_secret.db_credentials[0].arn, null)
}

output "db_credentials_secret_id" {
  description = "The ID of the Secrets Manager secret containing database credentials"
  value       = try(aws_secretsmanager_secret.db_credentials[0].id, null)
}

output "db_credentials_secret_name" {
  description = "The name of the Secrets Manager secret containing database credentials"
  value       = try(aws_secretsmanager_secret.db_credentials[0].name, null)
}

# ============================================================================
# Read Replica Outputs
# ============================================================================

output "read_replica_ids" {
  description = "List of read replica instance IDs"
  value       = [for replica in aws_db_instance.read_replica : replica.id]
}

output "read_replica_arns" {
  description = "List of read replica ARNs"
  value       = [for replica in aws_db_instance.read_replica : replica.arn]
}

output "read_replica_endpoints" {
  description = "List of read replica endpoints"
  value       = [for replica in aws_db_instance.read_replica : replica.endpoint]
}

output "read_replica_addresses" {
  description = "List of read replica addresses"
  value       = [for replica in aws_db_instance.read_replica : replica.address]
}

output "read_replicas" {
  description = "Map of all read replica attributes"
  value = {
    for idx, replica in aws_db_instance.read_replica : idx => {
      id                = replica.id
      arn               = replica.arn
      endpoint          = replica.endpoint
      address           = replica.address
      port              = replica.port
      status            = replica.status
      availability_zone = replica.availability_zone
    }
  }
}

# ============================================================================
# CloudWatch Alarm Outputs
# ============================================================================

output "cloudwatch_alarm_cpu_utilization_id" {
  description = "The ID of the CPU utilization CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.cpu_utilization[0].id, null)
}

output "cloudwatch_alarm_disk_queue_depth_id" {
  description = "The ID of the disk queue depth CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.disk_queue_depth[0].id, null)
}

output "cloudwatch_alarm_freeable_memory_id" {
  description = "The ID of the freeable memory CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.freeable_memory[0].id, null)
}

output "cloudwatch_alarm_free_storage_space_id" {
  description = "The ID of the free storage space CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.free_storage_space[0].id, null)
}

# ============================================================================
# Connection Information Output
# ============================================================================

output "connection_info" {
  description = "Database connection information"
  value = {
    endpoint = aws_db_instance.this.endpoint
    address  = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    database = aws_db_instance.this.db_name
    username = aws_db_instance.this.username
    engine   = aws_db_instance.this.engine
  }
  sensitive = true
}

# ============================================================================
# Connection String Output
# ============================================================================

output "connection_string" {
  description = "Database connection string (format depends on engine)"
  value = var.engine == "postgres" ? (
    "postgresql://${aws_db_instance.this.username}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
    ) : var.engine == "mysql" || var.engine == "mariadb" ? (
    "mysql://${aws_db_instance.this.username}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
    ) : (
    "${aws_db_instance.this.engine}://${aws_db_instance.this.username}@${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}"
  )
  sensitive = true
}
