# RDS Database Terraform Module

This module creates a production-ready Amazon RDS database instance with enterprise-grade features including multi-AZ deployment, read replicas, automated backups, encryption, enhanced monitoring, Performance Insights, and comprehensive CloudWatch alarms.

## Features

- **Multiple Database Engines**: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server
- **High Availability**: Multi-AZ deployment with automatic failover
- **Read Replicas**: Scale read workloads with up to 5 read replicas
- **Security**: KMS encryption, security groups, IAM database authentication
- **Backup & Recovery**: Automated backups, snapshots, point-in-time recovery
- **Monitoring**: Enhanced monitoring, Performance Insights, CloudWatch alarms
- **Secrets Management**: Automatic password generation and Secrets Manager integration
- **Parameter & Option Groups**: Customizable database configurations
- **Blue/Green Deployments**: Low-downtime updates
- **Comprehensive Tagging**: Cost allocation and resource management

## Usage

### Basic PostgreSQL Example

```hcl
module "rds_postgres" {
  source = "../../modules/rds"

  identifier = "myapp-postgres-db"
  engine     = "postgres"
  engine_version = "15.3"
  instance_class = "db.t3.medium"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true

  db_name  = "myappdb"
  username = "dbadmin"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.app_server.security_group_id]

  multi_az = true

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  tags = {
    Environment = "production"
    Application = "myapp"
  }
}
```

### Advanced MySQL Example with Read Replicas

```hcl
module "rds_mysql" {
  source = "../../modules/rds"

  identifier = "production-mysql-db"
  engine     = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.r6g.xlarge"

  # Storage configuration
  allocated_storage     = 500
  max_allocated_storage = 2000
  storage_type          = "gp3"
  storage_encrypted     = true
  storage_throughput    = 250

  # Database configuration
  db_name  = "production_db"
  username = "admin"
  manage_master_user_password = true

  # Network configuration
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  allowed_security_group_ids = [
    module.app_server.security_group_id,
    module.bastion.security_group_id
  ]

  # High availability
  multi_az = true

  # Read replicas
  create_read_replica       = true
  read_replica_count        = 2
  read_replica_instance_class = "db.r6g.large"

  # Backup configuration
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  skip_final_snapshot    = false

  # Maintenance
  maintenance_window         = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = true
  apply_immediately          = false

  # Parameter group
  create_db_parameter_group = true
  parameter_group_family    = "mysql8.0"
  parameters = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
      apply_method = "pending-reboot"
    }
  ]

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  performance_insights_enabled    = true
  performance_insights_retention_period = 731

  # CloudWatch alarms
  create_cloudwatch_alarms = true
  alarm_actions           = [aws_sns_topic.alerts.arn]
  cpu_utilization_threshold = 80
  freeable_memory_threshold = 1073741824 # 1 GB

  # IAM authentication
  iam_database_authentication_enabled = true

  # Secrets Manager
  create_db_credentials_secret = true

  # Deletion protection
  deletion_protection = true

  tags = {
    Environment = "production"
    Application = "myapp"
    Backup      = "daily"
    ManagedBy   = "terraform"
  }
}
```

### PostgreSQL with Custom Parameter Group

```hcl
module "rds_postgres_custom" {
  source = "../../modules/rds"

  identifier = "analytics-postgres"
  engine     = "postgres"
  engine_version = "15.3"
  instance_class = "db.r6g.2xlarge"

  allocated_storage = 1000
  storage_type      = "io1"
  iops              = 10000

  db_name  = "analytics"
  username = "analytics_admin"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = ["10.0.0.0/8"]

  multi_az = true

  # Custom parameter group for analytics workload
  create_db_parameter_group = true
  parameter_group_family    = "postgres15"
  parameters = [
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/4}"
      apply_method = "pending-reboot"
    },
    {
      name  = "effective_cache_size"
      value = "{DBInstanceClassMemory*3/4}"
    },
    {
      name  = "work_mem"
      value = "262144" # 256 MB
    },
    {
      name  = "maintenance_work_mem"
      value = "2097152" # 2 GB
    },
    {
      name  = "random_page_cost"
      value = "1.1"
    },
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true

  tags = {
    Environment = "production"
    Workload    = "analytics"
  }
}
```

### SQL Server Example

```hcl
module "rds_sqlserver" {
  source = "../../modules/rds"

  identifier = "app-sqlserver"
  engine     = "sqlserver-se"
  engine_version = "15.00.4335.1.v1"
  instance_class = "db.m5.xlarge"
  license_model  = "license-included"

  allocated_storage = 500
  storage_encrypted = true

  username = "admin"
  manage_master_user_password = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.app_server.security_group_id]

  multi_az = true

  backup_retention_period = 14

  # SQL Server specific
  timezone = "UTC"
  
  create_db_option_group = true
  major_engine_version   = "15.00"
  options = [
    {
      option_name = "SQLSERVER_BACKUP_RESTORE"
      option_settings = [
        {
          name  = "IAM_ROLE_ARN"
          value = aws_iam_role.sqlserver_backup.arn
        }
      ]
    }
  ]

  enabled_cloudwatch_logs_exports = ["error", "agent"]

  tags = {
    Environment = "production"
    Engine      = "sqlserver"
  }
}
```

### Oracle Example

```hcl
module "rds_oracle" {
  source = "../../modules/rds"

  identifier = "erp-oracle"
  engine     = "oracle-ee"
  engine_version = "19.0.0.0.ru-2023-07.rur-2023-07.r1"
  instance_class = "db.m5.2xlarge"
  license_model  = "bring-your-own-license"

  allocated_storage = 1000
  storage_type      = "io1"
  iops              = 10000

  username = "admin"
  character_set_name = "AL32UTF8"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.app_server.security_group_id]

  multi_az = true

  backup_retention_period = 30

  create_db_option_group = true
  major_engine_version   = "19"
  options = [
    {
      option_name = "STATSPACK"
    },
    {
      option_name = "OEM"
      port        = 1158
    }
  ]

  tags = {
    Environment = "production"
    Engine      = "oracle"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| random | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| random | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| identifier | The name of the RDS instance | `string` | n/a | yes |
| engine | The database engine to use | `string` | n/a | yes |
| engine_version | The engine version to use | `string` | n/a | yes |
| instance_class | The instance type of the RDS instance | `string` | n/a | yes |
| vpc_id | VPC ID where the database will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| allocated_storage | The allocated storage in gigabytes | `number` | n/a | yes |
| max_allocated_storage | Upper limit for storage autoscaling | `number` | `0` | no |
| storage_type | Storage type (standard, gp2, gp3, io1, io2) | `string` | `"gp3"` | no |
| storage_encrypted | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| db_name | The name of the database to create | `string` | `null` | no |
| username | Username for the master DB user | `string` | `"admin"` | no |
| master_password | Password for the master DB user | `string` | `null` | no |
| manage_master_user_password | Allow module to manage password | `bool` | `true` | no |
| port | The port on which the DB accepts connections | `number` | `null` | no |
| multi_az | Specifies if the RDS instance is multi-AZ | `bool` | `true` | no |
| publicly_accessible | Bool to control if instance is publicly accessible | `bool` | `false` | no |
| backup_retention_period | Days to retain backups | `number` | `7` | no |
| backup_window | Daily backup time range | `string` | `"03:00-04:00"` | no |
| maintenance_window | Weekly maintenance window | `string` | `"sun:04:00-sun:05:00"` | no |
| create_read_replica | Whether to create read replicas | `bool` | `false` | no |
| read_replica_count | Number of read replicas to create | `number` | `1` | no |
| performance_insights_enabled | Enable Performance Insights | `bool` | `true` | no |
| monitoring_interval | Enhanced monitoring interval | `number` | `60` | no |
| create_cloudwatch_alarms | Create CloudWatch alarms | `bool` | `true` | no |
| deletion_protection | Enable deletion protection | `bool` | `true` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

See `variables.tf` for complete list of inputs.

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_arn | The ARN of the RDS instance |
| db_instance_endpoint | The connection endpoint |
| db_instance_address | The address of the RDS instance |
| db_instance_port | The database port |
| security_group_id | The security group ID |
| db_credentials_secret_arn | ARN of Secrets Manager secret |
| read_replica_endpoints | List of read replica endpoints |
| connection_string | Database connection string |

See `outputs.tf` for complete list of outputs.

## Post-Deployment Steps

### 1. Retrieve Database Credentials

If you enabled Secrets Manager integration:

```bash
aws secretsmanager get-secret-value \
  --secret-id <secret-name> \
  --query SecretString \
  --output text | jq -r
```

### 2. Connect to Database

#### PostgreSQL
```bash
psql -h <endpoint> -U <username> -d <database>
```

#### MySQL
```bash
mysql -h <endpoint> -u <username> -p <database>
```

#### SQL Server
```bash
sqlcmd -S <endpoint> -U <username> -P <password>
```

### 3. Configure Application Connection

Use the connection string output or retrieve from Secrets Manager:

```python
# Python example
import boto3
import json

client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='<secret-name>')
credentials = json.loads(response['SecretString'])

connection_string = f"postgresql://{credentials['username']}:{credentials['password']}@{credentials['host']}:{credentials['port']}/{credentials['dbname']}"
```

## Security Best Practices

1. **Network Security**
   - Deploy in private subnets
   - Use security groups to restrict access
   - Never set `publicly_accessible = true` for production

2. **Encryption**
   - Always enable `storage_encrypted = true`
   - Use KMS keys for encryption
   - Enable encryption in transit (SSL/TLS)

3. **Authentication**
   - Use strong passwords (auto-generated recommended)
   - Store credentials in Secrets Manager
   - Enable IAM database authentication when possible
   - Rotate passwords regularly

4. **Backup & Recovery**
   - Set appropriate `backup_retention_period`
   - Test restore procedures regularly
   - Enable automated backups
   - Use snapshots for long-term retention

5. **Monitoring**
   - Enable Enhanced Monitoring
   - Enable Performance Insights
   - Set up CloudWatch alarms
   - Monitor slow query logs

6. **Updates**
   - Enable `auto_minor_version_upgrade`
   - Plan major version upgrades carefully
   - Test upgrades in non-production first
   - Use Blue/Green deployments for zero-downtime

## Performance Optimization

### Instance Sizing

Choose instance class based on workload:
- **T3/T4g**: Burstable, good for dev/test
- **M5/M6g**: General purpose, balanced compute/memory
- **R5/R6g**: Memory optimized, for large datasets
- **X2**: Extreme memory, for in-memory databases

### Storage Configuration

- **gp3**: Best for most workloads, configurable IOPS/throughput
- **io1/io2**: For high IOPS requirements (>16,000)
- Enable storage autoscaling with `max_allocated_storage`

### Parameter Tuning

Optimize based on engine and workload:

**PostgreSQL:**
- `shared_buffers`: 25% of RAM
- `effective_cache_size`: 75% of RAM
- `work_mem`: Based on concurrent queries
- `maintenance_work_mem`: For VACUUM operations

**MySQL:**
- `innodb_buffer_pool_size`: 75% of RAM
- `max_connections`: Based on application needs
- `innodb_log_file_size`: For write-heavy workloads

## Troubleshooting

### Connection Issues

1. Check security group rules
2. Verify subnet routing
3. Check network ACLs
4. Verify endpoint and port

### Performance Issues

1. Check CloudWatch metrics
2. Review Performance Insights
3. Analyze slow query logs
4. Check for blocking queries
5. Review parameter settings

### Backup/Restore Issues

1. Verify backup retention settings
2. Check backup window doesn't conflict with peak hours
3. Ensure sufficient storage for backups
4. Test restore procedures

### High Availability Issues

1. Verify Multi-AZ is enabled
2. Check subnet configuration (multiple AZs)
3. Review failover logs
4. Test failover procedures

## Cost Optimization

1. **Right-size instances**: Start small, scale as needed
2. **Use Reserved Instances**: For production workloads
3. **Enable storage autoscaling**: Avoid over-provisioning
4. **Use read replicas wisely**: Only when needed
5. **Optimize backup retention**: Balance cost vs. compliance
6. **Use Graviton instances**: Better price/performance (R6g, M6g)

## Examples

See the `examples/` directory for complete working examples:

- `examples/postgres/` - PostgreSQL database
- `examples/mysql/` - MySQL database
- `examples/sqlserver/` - SQL Server database
- `examples/oracle/` - Oracle database
- `examples/read-replicas/` - Multi-region read replicas

## License

MIT

## Authors

Created and maintained by DevOps Team

## References

- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
