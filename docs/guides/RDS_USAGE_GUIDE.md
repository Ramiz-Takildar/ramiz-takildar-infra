# RDS Module Usage Guide

> **Complete guide for deploying and managing Amazon RDS databases using the Infrastructure Provisioning Platform**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Options](#configuration-options)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [Common Use Cases](#common-use-cases)
8. [Database Management](#database-management)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The RDS module provisions production-ready Amazon RDS database instances with:

- **Multiple Engines**: PostgreSQL, MySQL, MariaDB, Oracle, SQL Server
- **High Availability**: Multi-AZ deployment with automatic failover
- **Read Replicas**: Up to 5 read replicas for scaling
- **Security**: KMS encryption, security groups, IAM authentication
- **Backups**: Automated backups with point-in-time recovery
- **Monitoring**: Enhanced monitoring, Performance Insights, CloudWatch alarms
- **Secrets Management**: Automatic credential generation and storage

## Prerequisites

### 1. AWS Resources Required

Before deploying an RDS instance, ensure you have:

- ✅ **VPC with Private Subnets**: At least 2 subnets in different AZs
- ✅ **Security Groups**: For application access (optional, can be created)
- ✅ **AWS OIDC Provider**: Configured for GitHub Actions
- ✅ **IAM Role**: With RDS permissions for GitHub Actions

### 2. Deploy VPC First

If you don't have a VPC, deploy one first:

```bash
# Go to GitHub Actions → VPC Infrastructure
# Run workflow with:
- Action: apply
- Environment: dev
- VPC Name: database-vpc
- VPC CIDR: 10.0.0.0/16
- Availability Zones: 3
- Create NAT Gateway: true
```

### 3. GitHub Secrets Required

Ensure these secrets are configured in your repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `VPC_ID` | VPC ID for RDS | `vpc-0123456789abcdef0` |
| `PRIVATE_SUBNET_IDS` | Private subnet IDs (JSON array) | `["subnet-xxx", "subnet-yyy", "subnet-zzz"]` |

### 4. Local Tools (for post-deployment)

- **psql**: For PostgreSQL (if using PostgreSQL)
- **mysql**: For MySQL/MariaDB (if using MySQL/MariaDB)
- **AWS CLI**: >= 2.0
- **jq**: For parsing JSON (optional)

## Quick Start

### 5-Minute PostgreSQL Deployment

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → RDS Infrastructure
   ```

2. **Click "Run workflow"**

3. **Use these settings for a basic database**:
   ```yaml
   Action: apply
   Environment: dev
   Identifier: my-app-db
   Engine: postgres
   Engine Version: 15.3
   Instance Class: db.t3.medium
   Allocated Storage: 100
   Multi-AZ: true
   Create Read Replicas: false
   ```

4. **Click "Run workflow"** and wait (~10-15 minutes)

5. **Retrieve credentials**:
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id my-app-db-db-credentials \
     --query SecretString --output text | jq -r
   ```

6. **Connect to database**:
   ```bash
   psql -h <endpoint> -U admin -d my_app_db
   ```

## Step-by-Step Deployment

### Step 1: Access GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **"RDS Infrastructure"** from the workflows list

### Step 2: Start Workflow

1. Click the **"Run workflow"** button (top right)
2. A form will appear with deployment options

### Step 3: Configure Basic Settings

#### Action Selection
```
Action: apply
```
- **plan**: Preview changes without applying
- **apply**: Create/update the database
- **destroy**: Delete the database

#### Environment Selection
```
Environment: dev
```
- **dev**: Development (no approval required, 7-day backups)
- **staging**: Staging (optional approval, 7-day backups)
- **prod**: Production (requires approval, 30-day backups, deletion protection)

#### Database Identifier
```
Identifier: production-postgres-db
```

**Identifier Rules**:
- Must start with a letter
- Can contain lowercase letters, numbers, and hyphens
- Must be unique in your AWS account/region
- Max 63 characters

### Step 4: Select Database Engine

#### Engine Selection
```
Engine: postgres
```

**Available Engines**:
- **postgres**: PostgreSQL (recommended for most use cases)
- **mysql**: MySQL
- **mariadb**: MariaDB (MySQL-compatible)
- **oracle-ee**: Oracle Enterprise Edition
- **oracle-se2**: Oracle Standard Edition 2
- **sqlserver-ee**: SQL Server Enterprise Edition
- **sqlserver-se**: SQL Server Standard Edition

#### Engine Version
```
Engine Version: 15.3
```

**Version Guidelines**:
- **PostgreSQL**: 15.x (latest), 14.x, 13.x
- **MySQL**: 8.0.x (latest), 5.7.x
- **MariaDB**: 10.11.x (latest), 10.6.x
- **Oracle**: 19.0.0.0.ru-2023-07.rur-2023-07.r1
- **SQL Server**: 15.00.4335.1.v1 (2019), 14.00.3451.2.v1 (2017)

**Recommendation**: Use the latest minor version for security patches

### Step 5: Configure Instance Size

#### Instance Class
```
Instance Class: db.t3.medium
```

**Instance Class Guide**:

| Class | vCPU | RAM | Use Case | Cost/Month* |
|-------|------|-----|----------|-------------|
| **db.t3.micro** | 2 | 1 GB | Dev/Test only | ~$15 |
| **db.t3.small** | 2 | 2 GB | Small apps | ~$30 |
| **db.t3.medium** | 2 | 4 GB | Medium apps | ~$60 |
| **db.t3.large** | 2 | 8 GB | Large apps | ~$120 |
| **db.m5.large** | 2 | 8 GB | Production | ~$140 |
| **db.m5.xlarge** | 4 | 16 GB | High traffic | ~$280 |
| **db.m5.2xlarge** | 8 | 32 GB | Very high traffic | ~$560 |
| **db.r5.large** | 2 | 16 GB | Memory-intensive | ~$180 |
| **db.r5.xlarge** | 4 | 32 GB | Large datasets | ~$360 |
| **db.r5.2xlarge** | 8 | 64 GB | Very large datasets | ~$720 |

*Approximate costs for us-east-1, single-AZ

**Sizing Recommendations**:
- **Dev/Test**: db.t3.micro or db.t3.small
- **Small Production**: db.t3.medium or db.t3.large
- **Medium Production**: db.m5.large or db.m5.xlarge
- **Large Production**: db.m5.2xlarge or db.r5.xlarge
- **Memory-Intensive**: db.r5.* series

### Step 6: Configure Storage

#### Allocated Storage
```
Allocated Storage: 100
```

**Storage Guidelines**:
- **Minimum**: 20 GB (100 GB recommended)
- **Maximum**: 64 TB (65,536 GB)
- **Auto-scaling**: Enabled by default (up to 2x allocated storage)

**Storage Types** (configured in module):
- **gp3**: General Purpose SSD (default, best for most workloads)
- **gp2**: General Purpose SSD (older generation)
- **io1/io2**: Provisioned IOPS (high-performance)

**Sizing Recommendations**:
- **Dev/Test**: 20-50 GB
- **Small Production**: 100-200 GB
- **Medium Production**: 200-500 GB
- **Large Production**: 500+ GB

### Step 7: Configure High Availability

#### Multi-AZ Deployment
```
Multi-AZ: true
```

**Multi-AZ Benefits**:
- ✅ Automatic failover (1-2 minutes)
- ✅ Synchronous replication
- ✅ 99.95% SLA (vs 99.5% single-AZ)
- ✅ Zero data loss
- ❌ 2x cost

**When to Use Multi-AZ**:
- ✅ Production databases
- ✅ Business-critical applications
- ✅ Compliance requirements
- ❌ Dev/test environments (to save cost)

### Step 8: Configure Read Replicas

#### Read Replica Configuration
```
Create Read Replicas: true
Read Replica Count: 2
```

**Read Replica Benefits**:
- ✅ Scale read workloads
- ✅ Offload reporting queries
- ✅ Disaster recovery
- ✅ Cross-region replication

**When to Use Read Replicas**:
- ✅ Read-heavy workloads
- ✅ Analytics/reporting
- ✅ Geographic distribution
- ❌ Write-heavy workloads

**Limitations**:
- Maximum 5 read replicas per primary
- Asynchronous replication (slight lag)
- Additional cost per replica

### Step 9: Review and Deploy

1. **Review all settings** carefully
2. **Click "Run workflow"**
3. **Monitor progress** in the Actions tab

**Deployment Timeline**:
- Security Scan: 2-3 minutes
- Terraform Plan: 3-5 minutes
- Approval (if prod): Variable
- Terraform Apply: 10-15 minutes
- **Total**: ~15-25 minutes

### Step 10: Verify Deployment

Check the **deployment summary** in the workflow run:

```
✅ Database Details
- Identifier: production-postgres-db
- Environment: prod
- Engine: postgres 15.3
- Instance Class: db.m5.large
- Endpoint: production-postgres-db.xxx.us-east-1.rds.amazonaws.com:5432
- Storage: 100 GB
- Multi-AZ: true
- Read Replicas: 2

✅ Credentials
Database credentials are stored in AWS Secrets Manager:
aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:...
```

## Configuration Options

### Basic Configuration

```yaml
# Minimum required configuration
identifier: "my-app-db"
engine: "postgres"
engine_version: "15.3"
instance_class: "db.t3.medium"
allocated_storage: 100

vpc_id: "vpc-xxx"
subnet_ids: ["subnet-xxx", "subnet-yyy"]

multi_az: true
```

### Production Configuration

```yaml
# Production-ready configuration
identifier: "production-postgres"
engine: "postgres"
engine_version: "15.3"
instance_class: "db.r5.xlarge"

# Storage
allocated_storage: 500
max_allocated_storage: 1000
storage_type: "gp3"
storage_encrypted: true

# Database
db_name: "production_db"
username: "admin"
manage_master_user_password: true

# Network
vpc_id: "vpc-xxx"
subnet_ids: ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
create_security_group: true
allowed_security_group_ids: ["sg-app-servers"]
publicly_accessible: false

# High Availability
multi_az: true

# Read Replicas
create_read_replica: true
read_replica_count: 2
read_replica_instance_class: "db.r5.large"

# Backups
backup_retention_period: 30
backup_window: "03:00-04:00"
skip_final_snapshot: false

# Maintenance
maintenance_window: "sun:04:00-sun:05:00"
auto_minor_version_upgrade: true
apply_immediately: false

# Parameter Group
create_db_parameter_group: true
parameter_group_family: "postgres15"
parameters: [
  {
    name: "max_connections"
    value: "500"
  },
  {
    name: "shared_buffers"
    value: "{DBInstanceClassMemory/4}"
    apply_method: "pending-reboot"
  },
  {
    name: "work_mem"
    value: "16384"  # 16 MB
  }
]

# Monitoring
enabled_cloudwatch_logs_exports: ["postgresql", "upgrade"]
monitoring_interval: 60
performance_insights_enabled: true
performance_insights_retention_period: 731  # 2 years

# CloudWatch Alarms
create_cloudwatch_alarms: true
alarm_actions: ["arn:aws:sns:us-east-1:123456789012:alerts"]
cpu_utilization_threshold: 80
freeable_memory_threshold: 1073741824  # 1 GB

# Security
iam_database_authentication_enabled: true
create_db_credentials_secret: true
deletion_protection: true

tags: {
  Environment: "production"
  ManagedBy: "terraform"
  CostCenter: "engineering"
  Backup: "daily"
}
```

## Post-Deployment Setup

### 1. Retrieve Database Credentials

#### Using AWS CLI
```bash
# Get secret ARN from workflow output
SECRET_ARN="arn:aws:secretsmanager:us-east-1:123456789012:secret:my-app-db-db-credentials-xxxxx"

# Retrieve credentials
aws secretsmanager get-secret-value \
  --secret-id $SECRET_ARN \
  --query SecretString \
  --output text | jq -r

# Output:
# {
#   "username": "admin",
#   "password": "xxxxxxxxxxxxx",
#   "engine": "postgres",
#   "host": "my-app-db.xxx.us-east-1.rds.amazonaws.com",
#   "port": 5432,
#   "dbname": "my_app_db"
# }
```

#### Save to Environment Variables
```bash
# Extract credentials
export DB_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq -r '.host')
export DB_PORT=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq -r '.port')
export DB_NAME=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq -r '.dbname')
export DB_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq -r '.username')
export DB_PASS=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query SecretString --output text | jq -r '.password')
```

### 2. Connect to Database

#### PostgreSQL
```bash
# Using psql
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

# Or with connection string
psql "postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME"

# Test connection
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"
```

#### MySQL/MariaDB
```bash
# Using mysql client
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS $DB_NAME

# Test connection
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "SELECT VERSION();"
```

#### SQL Server
```bash
# Using sqlcmd
sqlcmd -S $DB_HOST,$DB_PORT -U $DB_USER -P $DB_PASS -d $DB_NAME

# Test connection
sqlcmd -S $DB_HOST -U $DB_USER -P $DB_PASS -Q "SELECT @@VERSION"
```

### 3. Configure Application Connection

#### Python (PostgreSQL)
```python
import psycopg2
import boto3
import json

# Get credentials from Secrets Manager
client = boto3.client('secretsmanager')
response = client.get_secret_value(SecretId='my-app-db-db-credentials')
credentials = json.loads(response['SecretString'])

# Connect to database
conn = psycopg2.connect(
    host=credentials['host'],
    port=credentials['port'],
    database=credentials['dbname'],
    user=credentials['username'],
    password=credentials['password']
)

# Execute query
cursor = conn.cursor()
cursor.execute("SELECT version();")
print(cursor.fetchone())
```

#### Node.js (PostgreSQL)
```javascript
const { Client } = require('pg');
const AWS = require('aws-sdk');

// Get credentials from Secrets Manager
const secretsManager = new AWS.SecretsManager();
const secret = await secretsManager.getSecretValue({
  SecretId: 'my-app-db-db-credentials'
}).promise();

const credentials = JSON.parse(secret.SecretString);

// Connect to database
const client = new Client({
  host: credentials.host,
  port: credentials.port,
  database: credentials.dbname,
  user: credentials.username,
  password: credentials.password,
});

await client.connect();
const res = await client.query('SELECT version()');
console.log(res.rows[0]);
```

#### Java (PostgreSQL)
```java
import com.amazonaws.services.secretsmanager.*;
import com.amazonaws.services.secretsmanager.model.*;
import com.google.gson.Gson;
import java.sql.*;

// Get credentials from Secrets Manager
AWSSecretsManager client = AWSSecretsManagerClientBuilder.standard()
    .withRegion("us-east-1")
    .build();

GetSecretValueRequest request = new GetSecretValueRequest()
    .withSecretId("my-app-db-db-credentials");
GetSecretValueResult result = client.getSecretValue(request);

Gson gson = new Gson();
Credentials creds = gson.fromJson(result.getSecretString(), Credentials.class);

// Connect to database
String url = String.format("jdbc:postgresql://%s:%d/%s",
    creds.host, creds.port, creds.dbname);
Connection conn = DriverManager.getConnection(url, creds.username, creds.password);

// Execute query
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery("SELECT version()");
```

### 4. Create Initial Schema

#### PostgreSQL
```sql
-- Connect to database
psql -h $DB_HOST -U $DB_USER -d $DB_NAME

-- Create schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create tables
CREATE TABLE app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app.posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES app.users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON app.users(email);
CREATE INDEX idx_posts_user_id ON app.posts(user_id);

-- Grant permissions
CREATE USER app_user WITH PASSWORD 'secure_password';
GRANT USAGE ON SCHEMA app TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app TO app_user;
```

#### MySQL
```sql
-- Connect to database
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME

-- Create tables
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- Create user and grant permissions
CREATE USER 'app_user'@'%' IDENTIFIED BY 'secure_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON my_app_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

## Common Use Cases

### Use Case 1: Development Database

**Requirements**: Small, cost-effective database for development

```yaml
# Via GitHub Actions UI
Action: apply
Environment: dev
Identifier: dev-postgres
Engine: postgres
Engine Version: 15.3
Instance Class: db.t3.small
Allocated Storage: 20
Multi-AZ: false
Create Read Replicas: false
```

**Cost**: ~$30/month

**Features**:
- Single-AZ (cost savings)
- 7-day backups
- No read replicas
- Basic monitoring

### Use Case 2: Production Database with High Availability

**Requirements**: Multi-AZ, automated backups, monitoring

```yaml
# Via GitHub Actions UI
Action: apply
Environment: prod
Identifier: prod-postgres
Engine: postgres
Engine Version: 15.3
Instance Class: db.m5.large
Allocated Storage: 500
Multi-AZ: true
Create Read Replicas: false
```

**Additional Configuration** (in terraform.tfvars):
```hcl
backup_retention_period = 30
performance_insights_enabled = true
performance_insights_retention_period = 731
create_cloudwatch_alarms = true
deletion_protection = true
```

**Cost**: ~$280/month (Multi-AZ)

**Features**:
- Multi-AZ deployment
- 30-day backups
- Performance Insights
- CloudWatch alarms
- Deletion protection

### Use Case 3: Read-Heavy Workload with Replicas

**Requirements**: Scale read operations, analytics queries

```yaml
# Via GitHub Actions UI
Action: apply
Environment: prod
Identifier: prod-mysql
Engine: mysql
Engine Version: 8.0.35
Instance Class: db.r5.large
Allocated Storage: 500
Multi-AZ: true
Create Read Replicas: true
Read Replica Count: 2
```

**Application Configuration**:
```python
# Primary for writes
primary_conn = connect(host=primary_endpoint)

# Replicas for reads
replica_conn = connect(host=replica_endpoint)

# Write operation
primary_conn.execute("INSERT INTO users ...")

# Read operation
replica_conn.execute("SELECT * FROM users ...")
```

**Cost**: ~$540/month (primary + 2 replicas)

**Benefits**:
- 3x read capacity
- Offload analytics queries
- Geographic distribution

### Use Case 4: Multi-Region Disaster Recovery

**Requirements**: Cross-region replication for DR

**Step 1**: Deploy primary database
```yaml
# Primary in us-east-1
Action: apply
Environment: prod
Identifier: prod-postgres-primary
Engine: postgres
Engine Version: 15.3
Instance Class: db.m5.xlarge
Allocated Storage: 1000
Multi-AZ: true
```

**Step 2**: Create cross-region read replica
```bash
# Using AWS CLI
aws rds create-db-instance-read-replica \
  --db-instance-identifier prod-postgres-dr \
  --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:prod-postgres-primary \
  --db-instance-class db.m5.xlarge \
  --region us-west-2
```

**Step 3**: Promote replica during disaster
```bash
aws rds promote-read-replica \
  --db-instance-identifier prod-postgres-dr \
  --region us-west-2
```

## Database Management

### Backup and Restore

#### Manual Snapshot
```bash
# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier prod-postgres \
  --db-snapshot-identifier prod-postgres-manual-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier prod-postgres

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-postgres-restored \
  --db-snapshot-identifier prod-postgres-manual-20260516
```

#### Point-in-Time Recovery
```bash
# Restore to specific time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-postgres \
  --target-db-instance-identifier prod-postgres-pitr \
  --restore-time 2026-05-16T10:00:00Z
```

### Scaling

#### Vertical Scaling (Instance Size)
```bash
# Update instance class via GitHub Actions
# Or using AWS CLI:
aws rds modify-db-instance \
  --db-instance-identifier prod-postgres \
  --db-instance-class db.m5.2xlarge \
  --apply-immediately
```

#### Horizontal Scaling (Read Replicas)
```bash
# Add read replica via GitHub Actions
# Update: Create Read Replicas: true
# Update: Read Replica Count: 3
```

#### Storage Scaling
```bash
# Storage auto-scales automatically
# Or manually increase:
aws rds modify-db-instance \
  --db-instance-identifier prod-postgres \
  --allocated-storage 1000 \
  --apply-immediately
```

### Monitoring

#### CloudWatch Metrics
```bash
# CPU Utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=prod-postgres \
  --start-time 2026-05-16T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 3600 \
  --statistics Average

# Database Connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=prod-postgres \
  --start-time 2026-05-16T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 3600 \
  --statistics Average
```

#### Performance Insights
```bash
# View in AWS Console
# RDS → Databases → prod-postgres → Performance Insights

# Or query via API
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier db-XXXXXXXXXXXXX \
  --metric-queries file://metrics.json \
  --start-time 2026-05-16T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z
```

### Maintenance

#### Apply Pending Maintenance
```bash
# View pending maintenance
aws rds describe-pending-maintenance-actions \
  --resource-identifier arn:aws:rds:us-east-1:123456789012:db:prod-postgres

# Apply immediately
aws rds apply-pending-maintenance-action \
  --resource-identifier arn:aws:rds:us-east-1:123456789012:db:prod-postgres \
  --apply-action system-update \
  --opt-in-type immediate
```

#### Modify Maintenance Window
```bash
aws rds modify-db-instance \
  --db-instance-identifier prod-postgres \
  --preferred-maintenance-window sun:04:00-sun:05:00 \
  --apply-immediately
```

## Troubleshooting

### Issue 1: Cannot Connect to Database

**Symptoms**:
```bash
psql: error: connection to server at "xxx.rds.amazonaws.com" (10.0.1.100), port 5432 failed: Connection timed out
```

**Diagnosis**:
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx

# Check if database is available
aws rds describe-db-instances \
  --db-instance-identifier prod-postgres \
  --query 'DBInstances[0].DBInstanceStatus'
```

**Common Causes**:
1. **Security Group**: Not allowing inbound traffic
2. **Network**: Application not in same VPC
3. **Database Status**: Not in "available" state

**Solutions**:

**Fix Security Group**:
```bash
# Add inbound rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-database \
  --protocol tcp \
  --port 5432 \
  --source-group sg-application
```

**Check VPC Configuration**:
```bash
# Verify subnets
aws rds describe-db-subnet-groups \
  --db-subnet-group-name prod-postgres-subnet-group
```

**Wait for Database**:
```bash
# Database might be starting
aws rds wait db-instance-available \
  --db-instance-identifier prod-postgres
```

### Issue 2: High CPU Utilization

**Symptoms**:
```
CloudWatch Alarm: CPU Utilization > 80%
```

**Diagnosis**:
```sql
-- PostgreSQL: Check active queries
SELECT pid, usename, application_name, state, query, query_start
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start;

-- MySQL: Check processlist
SHOW FULL PROCESSLIST;
```

**Solutions**:

**Optimize Queries**:
```sql
-- PostgreSQL: Analyze slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Add indexes
CREATE INDEX idx_users_email ON users(email);
```

**Scale Up**:
```bash
# Increase instance size
# Via GitHub Actions or:
aws rds modify-db-instance \
  --db-instance-identifier prod-postgres \
  --db-instance-class db.m5.2xlarge \
  --apply-immediately
```

**Add Read Replicas**:
```bash
# Offload read queries to replicas
# Update workflow: Create Read Replicas: true
```

### Issue 3: Storage Full

**Symptoms**:
```
CloudWatch Alarm: FreeStorageSpace < 2 GB
```

**Diagnosis**:
```bash
# Check storage metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name FreeStorageSpace \
  --dimensions Name=DBInstanceIdentifier,Value=prod-postgres \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

**Solutions**:

**Increase Storage**:
```bash
# Storage auto-scales if enabled
# Or manually increase:
aws rds modify-db-instance \
  --db-instance-identifier prod-postgres \
  --allocated-storage 1000 \
  --apply-immediately
```

**Clean Up Data**:
```sql
-- PostgreSQL: Find large tables
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Archive old data
DELETE FROM logs WHERE created_at < NOW() - INTERVAL '90 days';
VACUUM FULL;
```

### Issue 4: Slow Queries

**Symptoms**:
```
Application timeouts
High database latency
```

**Diagnosis**:
```sql
-- PostgreSQL: Enable query logging
ALTER DATABASE mydb SET log_min_duration_statement = 1000; -- Log queries > 1s

-- Check slow queries
SELECT query, calls, total_time, mean_time, max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 20;

-- MySQL: Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

**Solutions**:

**Add Indexes**:
```sql
-- Analyze query plan
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';

-- Add missing index
CREATE INDEX idx_users_email ON users(email);
```

**Optimize Queries**:
```sql
-- Bad: SELECT *
SELECT * FROM users WHERE status = 'active';

-- Good: Select only needed columns
SELECT id, username, email FROM users WHERE status = 'active';

-- Use LIMIT
SELECT id, username FROM users ORDER BY created_at DESC LIMIT 100;
```

**Update Statistics**:
```sql
-- PostgreSQL
ANALYZE;

-- MySQL
ANALYZE TABLE users;
```

### Issue 5: Connection Pool Exhaustion

**Symptoms**:
```
Error: too many connections
FATAL: remaining connection slots are reserved
```

**Diagnosis**:
```sql
-- PostgreSQL: Check connections
SELECT count(*), state, usename, application_name
FROM pg_stat_activity
GROUP BY state, usename, application_name
ORDER BY count DESC;

-- Check max connections
SHOW max_connections;
```

**Solutions**:

**Increase max_connections**:
```bash
# Update parameter group via GitHub Actions
# Or create custom parameter group:
parameters = [
  {
    name  = "max_connections"
    value = "500"
  }
]
```

**Implement Connection Pooling**:
```python
# Python with connection pooling
from psycopg2 import pool

connection_pool = pool.SimpleConnectionPool(
    minconn=1,
    maxconn=20,
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASS
)

# Get connection from pool
conn = connection_pool.getconn()
# Use connection
# Return to pool
connection_pool.putconn(conn)
```

**Close Idle Connections**:
```sql
-- PostgreSQL: Set idle timeout
ALTER DATABASE mydb SET idle_in_transaction_session_timeout = '5min';

-- Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < NOW() - INTERVAL '1 hour';
```

## Best Practices

### 1. Security

✅ **Use Secrets Manager for credentials**
```python
# Never hardcode credentials
# Always use Secrets Manager
credentials = get_secret('my-app-db-credentials')
```

✅ **Enable encryption at rest**
```hcl
storage_encrypted = true
create_kms_key = true
```

✅ **Use SSL/TLS for connections**
```python
# PostgreSQL with SSL
conn = psycopg2.connect(
    host=DB_HOST,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASS,
    sslmode='require'
)
```

✅ **Restrict network access**
```hcl
publicly_accessible = false
allowed_security_group_ids = ["sg-app-servers"]
```

✅ **Enable IAM database authentication**
```hcl
iam_database_authentication_enabled = true
```

### 2. High Availability

✅ **Enable Multi-AZ for production**
```hcl
multi_az = true
```

✅ **Configure automated backups**
```hcl
backup_retention_period = 30  # 30 days for production
backup_window = "03:00-04:00"  # Low-traffic window
```

✅ **Test failover procedures**
```bash
# Simulate failover
aws rds reboot-db-instance \
  --db-instance-identifier prod-postgres \
  --force-failover
```

✅ **Use read replicas for DR**
```hcl
create_read_replica = true
read_replica_count = 1
```

### 3. Performance

✅ **Enable Performance Insights**
```hcl
performance_insights_enabled = true
performance_insights_retention_period = 731
```

✅ **Right-size instance class**
- Monitor CPU, memory, IOPS
- Scale up when consistently > 70%
- Scale down when consistently < 30%

✅ **Optimize queries**
```sql
-- Use EXPLAIN to analyze queries
EXPLAIN ANALYZE SELECT ...;

-- Add appropriate indexes
CREATE INDEX idx_name ON table(column);

-- Update statistics regularly
ANALYZE;
```

✅ **Use connection pooling**
- Application-level pooling (recommended)
- RDS Proxy for serverless workloads

### 4. Cost Optimization

✅ **Use appropriate instance types**
- Dev/Test: db.t3.* (burstable)
- Production: db.m5.* or db.r5.*

✅ **Enable storage autoscaling**
```hcl
max_allocated_storage = allocated_storage * 2
```

✅ **Use Reserved Instances for production**
- 1-year: ~30% savings
- 3-year: ~50% savings

✅ **Delete unnecessary snapshots**
```bash
# List old snapshots
aws rds describe-db-snapshots \
  --query 'DBSnapshots[?SnapshotCreateTime<`2025-01-01`]'

# Delete old snapshot
aws rds delete-db-snapshot \
  --db-snapshot-identifier old-snapshot
```

✅ **Stop dev/test databases when not in use**
```bash
# Stop database (max 7 days)
aws rds stop-db-instance \
  --db-instance-identifier dev-postgres

# Start database
aws rds start-db-instance \
  --db-instance-identifier dev-postgres
```

### 5. Monitoring

✅ **Set up CloudWatch alarms**
```hcl
create_cloudwatch_alarms = true
alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]
```

✅ **Monitor key metrics**
- CPU Utilization (< 80%)
- Freeable Memory (> 1 GB)
- Database Connections (< 80% of max)
- Read/Write IOPS
- Network throughput

✅ **Enable Enhanced Monitoring**
```hcl
monitoring_interval = 60  # 60 seconds
```

✅ **Review slow query logs**
```sql
-- PostgreSQL
SELECT * FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;
```

### 6. Backup and Recovery

✅ **Test restore procedures regularly**
```bash
# Restore to new instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier test-restore \
  --db-snapshot-identifier prod-snapshot

# Verify data
# Delete test instance
```

✅ **Use final snapshots before deletion**
```hcl
skip_final_snapshot = false  # For production
```

✅ **Enable point-in-time recovery**
```hcl
backup_retention_period = 30  # Enables PITR
```

✅ **Document recovery procedures**
- RTO (Recovery Time Objective)
- RPO (Recovery Point Objective)
- Step-by-step recovery process

## Maintenance Tasks

### Weekly Tasks

- [ ] Review CloudWatch metrics
- [ ] Check for slow queries
- [ ] Monitor storage usage
- [ ] Review connection counts

### Monthly Tasks

- [ ] Review and optimize queries
- [ ] Update statistics (ANALYZE)
- [ ] Review backup retention
- [ ] Check for available engine updates
- [ ] Review CloudWatch alarms
- [ ] Audit database users and permissions

### Quarterly Tasks

- [ ] Test backup restore procedures
- [ ] Review instance sizing
- [ ] Optimize costs (Reserved Instances)
- [ ] Review security configurations
- [ ] Update parameter groups if needed
- [ ] Test failover procedures (Multi-AZ)

## Cleanup and Destroy

### Before Destroying

⚠️ **CRITICAL**: RDS deletion is **PERMANENT**. All data will be lost unless you create a final snapshot.

**Pre-Destruction Checklist**:
- [ ] **Create final snapshot** (CRITICAL for data recovery)
- [ ] **Backup all databases** to S3 or external storage
- [ ] **Export database configurations** and schemas
- [ ] **Update application connection strings**
- [ ] **Delete read replicas** first
- [ ] **Notify team members**
- [ ] **Document database configuration**
- [ ] **Check for automated backups** to retain

### Method 1: Via GitHub Actions (Recommended)

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → RDS Infrastructure
   ```

2. **Click "Run workflow"**

3. **Configure destroy settings**:
   ```yaml
   Action: destroy
   Environment: dev  # or staging/prod
   DB Instance Name: myapp-db  # Must match existing
   Database Engine: postgres  # Must match existing
   Engine Version: 15.3  # Must match existing
   Instance Class: db.t3.medium  # Must match existing
   Allocated Storage: 100  # Must match existing
   Multi-AZ: false  # Must match existing
   AWS Region: us-east-1  # Must match existing
   ```

4. **IMPORTANT: Final Snapshot Decision**
   - Workflow will create final snapshot by default
   - Snapshot name: `{db-name}-final-snapshot-{timestamp}`
   - Can be used to restore database later

5. **Review destroy plan**
   - Workflow will show what will be destroyed
   - Verify the database name is correct

6. **Approve and execute** (for prod environment)
   - Production requires manual approval
   - **Triple-check database name** before approving

7. **Monitor destruction**
   - Watch the workflow logs
   - May take 5-10 minutes

**Expected Output**:
```
✅ RDS Instance Destroyed Successfully!

Destroyed Resources:
- DB Instance: myapp-db
- Final Snapshot: myapp-db-final-snapshot-20260516
- Read Replicas: 2 replicas deleted
- DB Subnet Group: myapp-db-subnet-group
- DB Parameter Group: myapp-db-params
- Security Groups: sg-xxx

Cleanup completed in 8 minutes.

⚠️ Final snapshot retained: myapp-db-final-snapshot-20260516
   - Can be used to restore database
   - Incurs storage costs (~$0.095/GB/month)
   - Delete manually if not needed
```

### Method 2: Via AWS CLI

#### Step 1: Create Final Snapshot (CRITICAL)

```bash
DB_INSTANCE="myapp-db"
SNAPSHOT_ID="${DB_INSTANCE}-final-snapshot-$(date +%Y%m%d-%H%M%S)"

# Create final snapshot
echo "Creating final snapshot: $SNAPSHOT_ID"
aws rds create-db-snapshot \
  --db-instance-identifier $DB_INSTANCE \
  --db-snapshot-identifier $SNAPSHOT_ID

# Wait for snapshot to complete
echo "Waiting for snapshot to complete (may take 5-10 minutes)..."
aws rds wait db-snapshot-completed \
  --db-snapshot-identifier $SNAPSHOT_ID

echo "✅ Final snapshot created: $SNAPSHOT_ID"
```

#### Step 2: Backup Database (Additional Safety)

```bash
# For PostgreSQL
pg_dump -h myapp-db.xxx.rds.amazonaws.com \
  -U postgres \
  -d mydb \
  -F c \
  -f backup-$(date +%Y%m%d).dump

# Upload to S3
aws s3 cp backup-$(date +%Y%m%d).dump s3://my-backups/rds/

# For MySQL
mysqldump -h myapp-db.xxx.rds.amazonaws.com \
  -u admin \
  -p \
  --all-databases \
  --single-transaction \
  --quick \
  --lock-tables=false \
  > backup-$(date +%Y%m%d).sql

# Upload to S3
gzip backup-$(date +%Y%m%d).sql
aws s3 cp backup-$(date +%Y%m%d).sql.gz s3://my-backups/rds/
```

#### Step 3: Delete Read Replicas First

```bash
# List read replicas
aws rds describe-db-instances \
  --query "DBInstances[?ReadReplicaSourceDBInstanceIdentifier=='$DB_INSTANCE'].DBInstanceIdentifier" \
  --output text

# Delete each read replica
READ_REPLICAS=$(aws rds describe-db-instances \
  --query "DBInstances[?ReadReplicaSourceDBInstanceIdentifier=='$DB_INSTANCE'].DBInstanceIdentifier" \
  --output text)

for REPLICA in $READ_REPLICAS; do
  echo "Deleting read replica: $REPLICA"
  aws rds delete-db-instance \
    --db-instance-identifier $REPLICA \
    --skip-final-snapshot
  
  # Wait for deletion
  aws rds wait db-instance-deleted \
    --db-instance-identifier $REPLICA
done
```

#### Step 4: Delete Primary DB Instance

**Option A: With Final Snapshot (Recommended)**
```bash
# Delete with final snapshot
aws rds delete-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --final-db-snapshot-identifier $SNAPSHOT_ID \
  --delete-automated-backups

# Wait for deletion
echo "Waiting for DB instance to delete (may take 5-10 minutes)..."
aws rds wait db-instance-deleted \
  --db-instance-identifier $DB_INSTANCE

echo "✅ DB instance deleted with final snapshot"
```

**Option B: Without Final Snapshot (Not Recommended)**
```bash
# ⚠️ WARNING: No recovery possible!
aws rds delete-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --skip-final-snapshot \
  --delete-automated-backups

# Wait for deletion
aws rds wait db-instance-deleted \
  --db-instance-identifier $DB_INSTANCE
```

#### Step 5: Clean Up Associated Resources

```bash
# Delete DB subnet group
DB_SUBNET_GROUP="${DB_INSTANCE}-subnet-group"
aws rds delete-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP

# Delete DB parameter group (if custom)
DB_PARAM_GROUP="${DB_INSTANCE}-params"
aws rds delete-db-parameter-group \
  --db-parameter-group-name $DB_PARAM_GROUP

# Delete DB option group (if custom)
DB_OPTION_GROUP="${DB_INSTANCE}-options"
aws rds delete-option-group \
  --option-group-name $DB_OPTION_GROUP

# Delete security group
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=${DB_INSTANCE}-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

if [ "$SG_ID" != "None" ]; then
  aws ec2 delete-security-group --group-id $SG_ID
fi

# Delete CloudWatch alarms
aws cloudwatch delete-alarms \
  --alarm-names \
    "${DB_INSTANCE}-cpu-high" \
    "${DB_INSTANCE}-storage-low" \
    "${DB_INSTANCE}-connections-high"
```

### Method 3: Via Terraform (Direct)

```bash
# Navigate to environment directory
cd terraform/environments/dev/rds

# IMPORTANT: Create snapshot first
DB_INSTANCE="myapp-db"
aws rds create-db-snapshot \
  --db-instance-identifier $DB_INSTANCE \
  --db-snapshot-identifier ${DB_INSTANCE}-manual-snapshot-$(date +%Y%m%d)

# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy -auto-approve

# Or destroy specific resource
terraform destroy -target=module.rds
```

### Automated Cleanup Script

```bash
#!/bin/bash
# delete-rds-instance.sh - Automated RDS deletion with safety checks

set -e

DB_INSTANCE="$1"
SKIP_SNAPSHOT="${2:-false}"

if [ -z "$DB_INSTANCE" ]; then
  echo "Usage: $0 <db-instance-identifier> [skip-snapshot]"
  echo "Example: $0 myapp-db false"
  exit 1
fi

echo "Starting RDS deletion process for: $DB_INSTANCE"

# Check if instance exists
if ! aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE &>/dev/null; then
  echo "❌ Error: DB instance $DB_INSTANCE not found"
  exit 1
fi

# Get instance details
echo "Fetching instance details..."
DB_ENGINE=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBInstances[0].Engine' \
  --output text)

DB_SIZE=$(aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBInstances[0].AllocatedStorage' \
  --output text)

echo "Instance: $DB_INSTANCE"
echo "Engine: $DB_ENGINE"
echo "Size: ${DB_SIZE}GB"

# Confirmation prompt
read -p "⚠️  Are you sure you want to delete this database? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Deletion cancelled"
  exit 0
fi

# Step 1: Create final snapshot (unless skipped)
if [ "$SKIP_SNAPSHOT" != "true" ]; then
  SNAPSHOT_ID="${DB_INSTANCE}-final-snapshot-$(date +%Y%m%d-%H%M%S)"
  echo "Step 1: Creating final snapshot: $SNAPSHOT_ID"
  
  aws rds create-db-snapshot \
    --db-instance-identifier $DB_INSTANCE \
    --db-snapshot-identifier $SNAPSHOT_ID
  
  echo "Waiting for snapshot to complete..."
  aws rds wait db-snapshot-completed \
    --db-snapshot-identifier $SNAPSHOT_ID
  
  echo "✅ Snapshot created: $SNAPSHOT_ID"
fi

# Step 2: Delete read replicas
echo "Step 2: Checking for read replicas..."
READ_REPLICAS=$(aws rds describe-db-instances \
  --query "DBInstances[?ReadReplicaSourceDBInstanceIdentifier=='$DB_INSTANCE'].DBInstanceIdentifier" \
  --output text)

if [ ! -z "$READ_REPLICAS" ]; then
  for REPLICA in $READ_REPLICAS; do
    echo "Deleting read replica: $REPLICA"
    aws rds delete-db-instance \
      --db-instance-identifier $REPLICA \
      --skip-final-snapshot
    
    aws rds wait db-instance-deleted \
      --db-instance-identifier $REPLICA
  done
fi

# Step 3: Delete primary instance
echo "Step 3: Deleting primary DB instance..."
if [ "$SKIP_SNAPSHOT" != "true" ]; then
  aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE \
    --final-db-snapshot-identifier $SNAPSHOT_ID \
    --delete-automated-backups
else
  aws rds delete-db-instance \
    --db-instance-identifier $DB_INSTANCE \
    --skip-final-snapshot \
    --delete-automated-backups
fi

echo "Waiting for DB instance to delete..."
aws rds wait db-instance-deleted \
  --db-instance-identifier $DB_INSTANCE

# Step 4: Clean up resources
echo "Step 4: Cleaning up associated resources..."

# Delete subnet group
aws rds delete-db-subnet-group \
  --db-subnet-group-name "${DB_INSTANCE}-subnet-group" 2>/dev/null || true

# Delete parameter group
aws rds delete-db-parameter-group \
  --db-parameter-group-name "${DB_INSTANCE}-params" 2>/dev/null || true

# Delete option group
aws rds delete-option-group \
  --option-group-name "${DB_INSTANCE}-options" 2>/dev/null || true

echo "✅ RDS instance $DB_INSTANCE deleted successfully!"

if [ "$SKIP_SNAPSHOT" != "true" ]; then
  echo ""
  echo "📸 Final snapshot: $SNAPSHOT_ID"
  echo "   - Can be used to restore database"
  echo "   - Storage cost: ~\$0.095/GB/month (${DB_SIZE}GB = ~\$$(echo "$DB_SIZE * 0.095" | bc)/month)"
  echo "   - Delete with: aws rds delete-db-snapshot --db-snapshot-identifier $SNAPSHOT_ID"
fi
```

Usage:
```bash
chmod +x delete-rds-instance.sh

# With final snapshot (recommended)
./delete-rds-instance.sh myapp-db false

# Without final snapshot (dangerous!)
./delete-rds-instance.sh myapp-db true
```

### Verify Cleanup

```bash
# Verify instance is deleted
aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE
# Should return error: DBInstanceNotFound

# List remaining snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,AllocatedStorage]' \
  --output table

# Check for orphaned resources
aws rds describe-db-subnet-groups \
  --query "DBSubnetGroups[?contains(DBSubnetGroupName, '$DB_INSTANCE')]"

aws rds describe-db-parameter-groups \
  --query "DBParameterGroups[?contains(DBParameterGroupName, '$DB_INSTANCE')]"
```

### Cost Savings After Destruction

**Immediate Savings**:
- DB instance charges stop immediately
- Multi-AZ charges stop (if enabled)
- Read replica charges stop
- IOPS charges stop (if provisioned)
- Backup storage charges stop (if deleted)

**Ongoing Costs**:
- Snapshot storage: ~$0.095/GB/month

**Example**:
```
Before:
- db.t3.medium (Multi-AZ): $120/month
- 2 read replicas: $120/month
- 100GB storage: $11.50/month
- Automated backups: $9.50/month
Total: $261/month

After (with snapshot):
- 100GB snapshot: $9.50/month
Savings: $251.50/month or $3,018/year
```

### Restore from Snapshot

If you need to restore the database:

```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier myapp-db-restored \
  --db-snapshot-identifier myapp-db-final-snapshot-20260516 \
  --db-instance-class db.t3.medium \
  --vpc-security-group-ids sg-xxx \
  --db-subnet-group-name myapp-subnet-group

# Wait for availability
aws rds wait db-instance-available \
  --db-instance-identifier myapp-db-restored

# Get new endpoint
aws rds describe-db-instances \
  --db-instance-identifier myapp-db-restored \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### Troubleshooting Destroy Issues

#### Issue: Cannot Delete - Deletion Protection Enabled

**Error**: "Cannot delete protected DB instance"

**Solution**:
```bash
# Disable deletion protection
aws rds modify-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --no-deletion-protection \
  --apply-immediately

# Wait for modification
aws rds wait db-instance-available \
  --db-instance-identifier $DB_INSTANCE

# Now delete
aws rds delete-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --final-db-snapshot-identifier final-snapshot
```

#### Issue: Cannot Delete - Read Replicas Exist

**Error**: "Cannot delete DB instance with read replicas"

**Solution**:
```bash
# Delete all read replicas first
READ_REPLICAS=$(aws rds describe-db-instances \
  --query "DBInstances[?ReadReplicaSourceDBInstanceIdentifier=='$DB_INSTANCE'].DBInstanceIdentifier" \
  --output text)

for REPLICA in $READ_REPLICAS; do
  aws rds delete-db-instance \
    --db-instance-identifier $REPLICA \
    --skip-final-snapshot
  aws rds wait db-instance-deleted --db-instance-identifier $REPLICA
done

# Then delete primary
aws rds delete-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --final-db-snapshot-identifier final-snapshot
```

#### Issue: Snapshot Creation Failed

**Error**: "Cannot create snapshot"

**Solution**:
```bash
# Check instance status
aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBInstances[0].DBInstanceStatus'

# Wait for instance to be available
aws rds wait db-instance-available \
  --db-instance-identifier $DB_INSTANCE

# Try snapshot again
aws rds create-db-snapshot \
  --db-instance-identifier $DB_INSTANCE \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

#### Issue: Cannot Delete Subnet Group

**Error**: "DB subnet group is in use"

**Solution**:
```bash
# Check which instances are using it
aws rds describe-db-instances \
  --query "DBInstances[?DBSubnetGroup.DBSubnetGroupName=='$DB_SUBNET_GROUP'].[DBInstanceIdentifier]"

# Delete those instances first
# Then delete subnet group
aws rds delete-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP
```

### Best Practices for Safe Deletion

✅ **Always create final snapshot**
```bash
# Never skip final snapshot for production
aws rds delete-db-instance \
  --db-instance-identifier $DB_INSTANCE \
  --final-db-snapshot-identifier final-snapshot-$(date +%Y%m%d)
```

✅ **Export data before deletion**
```bash
# PostgreSQL
pg_dump -h endpoint -U user -d dbname -F c -f backup.dump

# MySQL
mysqldump -h endpoint -u user -p --all-databases > backup.sql
```

✅ **Test restore procedure**
```bash
# Restore to test instance
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier test-restore \
  --db-snapshot-identifier final-snapshot

# Verify data
# Then delete test instance
```

✅ **Document connection strings**
```bash
# Save endpoint information
aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBInstances[0].Endpoint' > endpoint-info.json
```

✅ **Retain snapshots for compliance**
```bash
# Tag snapshots for retention
aws rds add-tags-to-resource \
  --resource-name arn:aws:rds:region:account:snapshot:snapshot-id \
  --tags Key=Retention,Value=7years Key=Compliance,Value=required
```

✅ **Use automated backups**
```hcl
backup_retention_period = 30  # Keep 30 days of backups
backup_window          = "03:00-04:00"
```

## Additional Resources

- [Amazon RDS Documentation](https://docs.aws.amazon.com/rds/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [RDS Performance Insights](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check AWS CloudWatch logs
- Review RDS events in AWS Console
- Contact DevOps team

---

**Last Updated**: May 2026