# ============================================================================
# RDS Database Module - Variables
# ============================================================================

# ============================================================================
# Database Identifier
# ============================================================================

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.identifier))
    error_message = "Identifier must start with a letter and can only contain lowercase alphanumeric characters and hyphens."
  }
}

# ============================================================================
# Engine Configuration
# ============================================================================

variable "engine" {
  description = "The database engine to use (mysql, postgres, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web)"
  type        = string

  validation {
    condition = contains([
      "mysql", "postgres", "mariadb",
      "oracle-ee", "oracle-se2",
      "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"
    ], var.engine)
    error_message = "Engine must be one of: mysql, postgres, mariadb, oracle-ee, oracle-se2, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web."
  }
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string

  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "Instance class must start with 'db.' (e.g., db.t3.micro)."
  }
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = null
}

# ============================================================================
# Storage Configuration
# ============================================================================

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage. Set to 0 to disable storage autoscaling"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: standard, gp2, gp3, io1, io2."
  }
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' or 'io2'"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "The storage throughput value for the DB instance. Only valid for gp3"
  type        = number
  default     = null
}

# ============================================================================
# Database Configuration
# ============================================================================

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"

  validation {
    condition     = length(var.username) >= 1 && length(var.username) <= 16
    error_message = "Username must be between 1 and 16 characters."
  }
}

variable "master_password" {
  description = "Password for the master DB user. If not provided and manage_master_user_password is true, a random password will be generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow the module to manage the master user password (generate random password if not provided)"
  type        = bool
  default     = true
}

variable "master_password_length" {
  description = "Length of the random password to generate if manage_master_user_password is true and master_password is not provided"
  type        = number
  default     = 32

  validation {
    condition     = var.master_password_length >= 8 && var.master_password_length <= 128
    error_message = "Password length must be between 8 and 128 characters."
  }
}

variable "port" {
  description = "The port on which the DB accepts connections. If not specified, uses default port for the engine"
  type        = number
  default     = null
}

variable "character_set_name" {
  description = "The character set name to use for DB encoding in Oracle and Microsoft SQL instances"
  type        = string
  default     = null
}

variable "license_model" {
  description = "License model information for this DB instance. Valid values: license-included, bring-your-own-license, general-public-license"
  type        = string
  default     = null
}

variable "timezone" {
  description = "Time zone of the DB instance. Only supported for Microsoft SQL Server"
  type        = string
  default     = null
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID (vpc-xxxxxxxx)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "create_db_subnet_group" {
  description = "Whether to create a database subnet group"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If not specified, will be created in the default VPC"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Whether to create a security group for the RDS instance"
  type        = bool
  default     = true
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate. Only used if create_security_group is false"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

# ============================================================================
# High Availability Configuration
# ============================================================================

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "The AZ for the RDS instance. Only used if multi_az is false"
  type        = string
  default     = null
}

# ============================================================================
# Backup Configuration
# ============================================================================

variable "backup_retention_period" {
  description = "The days to retain backups for. Must be between 0 and 35"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'"
  type        = string
  default     = "03:00-04:00"
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Instance tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot"
  type        = string
  default     = null
}

# ============================================================================
# Maintenance Configuration
# ============================================================================

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Example: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

# ============================================================================
# Parameter and Option Groups
# ============================================================================

variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  type        = bool
  default     = true
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate. Only used if create_db_parameter_group is false"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "parameters" {
  description = "A list of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

variable "create_db_option_group" {
  description = "Whether to create a database option group"
  type        = bool
  default     = false
}

variable "option_group_name" {
  description = "Name of the DB option group to associate. Only used if create_db_option_group is false"
  type        = string
  default     = null
}

variable "options" {
  description = "A list of options to apply"
  type        = any
  default     = []
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql, upgrade"
  type        = list(string)
  default     = null
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected. Valid Values: 0, 1, 5, 10, 15, 30, 60"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data. Valid values: 7, 731 (2 years) or a multiple of 31"
  type        = number
  default     = 7

  validation {
    condition     = var.performance_insights_retention_period == 7 || var.performance_insights_retention_period == 731 || (var.performance_insights_retention_period % 31 == 0 && var.performance_insights_retention_period > 0)
    error_message = "Performance Insights retention period must be 7, 731, or a multiple of 31."
  }
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

# ============================================================================
# CloudWatch Alarms Configuration
# ============================================================================

variable "create_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the RDS instance"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}

variable "cpu_utilization_threshold" {
  description = "The maximum percentage of CPU utilization"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_utilization_threshold > 0 && var.cpu_utilization_threshold <= 100
    error_message = "CPU utilization threshold must be between 0 and 100."
  }
}

variable "disk_queue_depth_threshold" {
  description = "The maximum number of outstanding IOs (read/write requests) waiting to access the disk"
  type        = number
  default     = 64
}

variable "freeable_memory_threshold" {
  description = "The minimum amount of available random access memory in bytes"
  type        = number
  default     = 268435456 # 256 MB
}

variable "free_storage_space_threshold" {
  description = "The minimum amount of available storage space in bytes"
  type        = number
  default     = 2147483648 # 2 GB
}

# ============================================================================
# Encryption Configuration
# ============================================================================

variable "create_kms_key" {
  description = "Whether to create a KMS key for RDS encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If not specified and create_kms_key is true, a new key will be created"
  type        = string
  default     = null
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
# IAM Configuration
# ============================================================================

variable "iam_database_authentication_enabled" {
  description = "Specifies whether mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}

# ============================================================================
# Secrets Manager Configuration
# ============================================================================

variable "create_db_credentials_secret" {
  description = "Whether to create a Secrets Manager secret for database credentials"
  type        = bool
  default     = true
}

# ============================================================================
# Deletion Protection
# ============================================================================

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = true
}

# ============================================================================
# Domain Configuration (for SQL Server)
# ============================================================================

variable "domain" {
  description = "The ID of the Directory Service Active Directory domain to create the instance in"
  type        = string
  default     = null
}

variable "domain_iam_role_name" {
  description = "The name of the IAM role to be used when making API calls to the Directory Service"
  type        = string
  default     = null
}

# ============================================================================
# Read Replica Configuration
# ============================================================================

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database"
  type        = string
  default     = null
}

variable "create_read_replica" {
  description = "Whether to create read replicas"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1

  validation {
    condition     = var.read_replica_count >= 0 && var.read_replica_count <= 5
    error_message = "Read replica count must be between 0 and 5."
  }
}

variable "read_replica_instance_class" {
  description = "The instance class for read replicas. If not specified, uses the same as the primary instance"
  type        = string
  default     = null
}

variable "read_replica_multi_az" {
  description = "Specifies if the read replicas are multi-AZ"
  type        = bool
  default     = false
}

variable "read_replica_availability_zones" {
  description = "List of availability zones for read replicas. Only used if read_replica_multi_az is false"
  type        = list(string)
  default     = []
}

# ============================================================================
# Blue/Green Deployment
# ============================================================================

variable "blue_green_update_enabled" {
  description = "Enables low-downtime updates using RDS Blue/Green deployments"
  type        = bool
  default     = false
}

# ============================================================================
# Timeouts
# ============================================================================

variable "timeouts" {
  description = "Map of timeouts for create, update, and delete operations"
  type        = map(string)
  default = {
    create = "40m"
    update = "80m"
    delete = "60m"
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
