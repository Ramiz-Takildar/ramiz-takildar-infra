# S3 Module Usage Guide

> **Complete guide for deploying and managing Amazon S3 buckets using the Infrastructure Provisioning Platform**

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Configuration Options](#configuration-options)
6. [Post-Deployment Setup](#post-deployment-setup)
7. [Common Use Cases](#common-use-cases)
8. [Bucket Management](#bucket-management)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Overview

The S3 module provisions Amazon S3 buckets with enterprise features:

- **Security**: Encryption, versioning, access control
- **Lifecycle Management**: Automatic data tiering and expiration
- **Replication**: Cross-region and same-region replication
- **Access Logging**: Track bucket access
- **CORS**: Cross-origin resource sharing
- **Static Website Hosting**: Host static websites
- **Object Lock**: Compliance and retention
- **Intelligent Tiering**: Automatic cost optimization

## Prerequisites

### 1. AWS Resources Required

Before deploying S3 buckets, ensure you have:

- ✅ **AWS OIDC Provider**: Configured for GitHub Actions
- ✅ **IAM Role**: With S3 permissions for GitHub Actions
- ✅ **KMS Key** (Optional): For encryption
- ✅ **Logging Bucket** (Optional): For access logs

### 2. GitHub Secrets Required

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ROLE_ARN` | IAM role for OIDC | `arn:aws:iam::123456789012:role/GitHubActionsRole` |
| `KMS_KEY_ID` | (Optional) KMS key for encryption | `arn:aws:kms:us-east-1:123456789012:key/...` |
| `LOGGING_BUCKET` | (Optional) Bucket for access logs | `my-logs-bucket` |

### 3. Bucket Naming Rules

- Must be globally unique across all AWS accounts
- 3-63 characters long
- Lowercase letters, numbers, hyphens, periods
- Must start and end with letter or number
- Cannot be formatted as IP address (192.168.1.1)

## Quick Start

### 5-Minute Deployment

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → S3 Infrastructure
   ```

2. **Click "Run workflow"**

3. **Use these settings**:
   ```yaml
   Action: apply
   Environment: dev
   Bucket Name: my-app-data-dev-20260516
   Enable Versioning: true
   Enable Encryption: true
   Block Public Access: true
   Enable Lifecycle Rules: false
   ```

4. **Click "Run workflow"** and wait (~2-3 minutes)

5. **Upload files**:
   ```bash
   # Upload file
   aws s3 cp myfile.txt s3://my-app-data-dev-20260516/

   # List files
   aws s3 ls s3://my-app-data-dev-20260516/
   ```

## Step-by-Step Deployment

### Step 1: Access GitHub Actions

1. Go to your GitHub repository
2. Click on the **Actions** tab
3. Select **"S3 Infrastructure"** from the workflows list

### Step 2: Start Workflow

1. Click the **"Run workflow"** button
2. A form will appear with deployment options

### Step 3: Configure Basic Settings

#### Action Selection
```
Action: apply
```
- **plan**: Preview changes
- **apply**: Create/update bucket
- **destroy**: Delete bucket (must be empty)

#### Environment Selection
```
Environment: dev
```
- **dev**: Development (no approval)
- **staging**: Staging (optional approval)
- **prod**: Production (requires approval, additional protection)

#### Bucket Name
```
Bucket Name: my-app-data-prod
```

**Naming Best Practices**:
- Include environment: `myapp-data-prod`
- Include date for uniqueness: `myapp-data-20260516`
- Use organization prefix: `acme-myapp-data`
- Avoid sensitive information in name

**Examples**:
- ✅ `acme-app-data-prod`
- ✅ `mycompany-backups-us-east-1`
- ✅ `website-assets-20260516`
- ❌ `my_bucket` (underscore not allowed)
- ❌ `MyBucket` (uppercase not allowed)
- ❌ `192.168.1.1` (IP format not allowed)

### Step 4: Configure Security

#### Enable Versioning
```
Enable Versioning: true
```

**Benefits**:
- ✅ Protect against accidental deletion
- ✅ Recover previous versions
- ✅ Compliance requirements
- ❌ Additional storage costs

**When to Enable**:
- ✅ Production data
- ✅ Critical documents
- ✅ Compliance requirements
- ❌ Temporary data
- ❌ Log files (use lifecycle instead)

#### Enable Encryption
```
Enable Encryption: true
```

**Encryption Options**:
- **SSE-S3**: AWS-managed keys (default)
- **SSE-KMS**: Customer-managed keys (more control)
- **SSE-C**: Customer-provided keys (you manage)

**When to Enable**:
- ✅ Always (best practice)
- ✅ Compliance requirements
- ✅ Sensitive data

#### Block Public Access
```
Block Public Access: true
```

**Settings**:
- Block public ACLs
- Ignore public ACLs
- Block public bucket policies
- Restrict public buckets

**When to Enable**:
- ✅ Always (unless hosting public website)
- ✅ Private data
- ✅ Application data
- ❌ Public website hosting
- ❌ Public downloads

### Step 5: Configure Lifecycle Rules

```
Enable Lifecycle Rules: true
```

**Common Lifecycle Policies**:

1. **Archive Old Data**:
   - Transition to STANDARD_IA after 30 days
   - Transition to GLACIER after 90 days
   - Delete after 365 days

2. **Clean Up Incomplete Uploads**:
   - Delete incomplete multipart uploads after 7 days

3. **Version Management**:
   - Delete old versions after 90 days
   - Keep only last 5 versions

**Cost Savings**:
- STANDARD_IA: 50% cheaper than STANDARD
- GLACIER: 80% cheaper than STANDARD
- DEEP_ARCHIVE: 95% cheaper than STANDARD

### Step 6: Review and Deploy

1. **Review all settings**
2. **Click "Run workflow"**
3. **Monitor progress**

**Deployment Timeline**:
- Security Scan: 2-3 minutes
- Terraform Plan: 1-2 minutes
- Approval (if prod): Variable
- Terraform Apply: 1-2 minutes
- **Total**: ~3-10 minutes

### Step 7: Verify Deployment

Check the **deployment summary**:

```
✅ S3 Bucket Created Successfully!

Bucket Details:
- Bucket Name: my-app-data-prod
- Environment: prod
- Region: us-east-1
- Versioning: Enabled
- Encryption: Enabled
- Public Access: Blocked

Bucket ARN: arn:aws:s3:::my-app-data-prod

Upload Command:
aws s3 cp myfile.txt s3://my-app-data-prod/
```

## Configuration Options

### Basic Configuration

```hcl
# Minimum required
bucket_name = "my-app-data"

# Security
enable_versioning = true
enable_encryption = true
block_public_access = true
```

### Production Configuration

```hcl
# Production-ready bucket
bucket_name = "acme-app-data-prod"

# Versioning
enable_versioning = true

# Encryption
enable_encryption = true
kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/..."

# Public Access
block_public_access = true

# Lifecycle Rules
lifecycle_rules = [
  {
    id      = "archive-old-data"
    enabled = true
    
    transition = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
    
    expiration = {
      days = 365
    }
  },
  {
    id      = "cleanup-incomplete-uploads"
    enabled = true
    
    abort_incomplete_multipart_upload_days = 7
  },
  {
    id      = "delete-old-versions"
    enabled = true
    
    noncurrent_version_expiration = {
      days = 90
    }
  }
]

# Access Logging
enable_logging = true
logging_bucket = "acme-logs-bucket"
logging_prefix = "s3-access-logs/"

# Replication (for DR)
enable_replication = true
replication_configuration = {
  role = "arn:aws:iam::123456789012:role/s3-replication-role"
  
  rules = [
    {
      id       = "replicate-all"
      status   = "Enabled"
      priority = 1
      
      destination = {
        bucket        = "arn:aws:s3:::acme-app-data-prod-replica"
        storage_class = "STANDARD_IA"
      }
    }
  ]
}

# CORS (if needed for web apps)
cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://myapp.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
]

# Tags
tags = {
  Environment = "production"
  Application = "myapp"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  DataClass   = "confidential"
}
```

## Post-Deployment Setup

### 1. Upload Files

#### Using AWS CLI
```bash
# Upload single file
aws s3 cp myfile.txt s3://my-bucket/

# Upload with metadata
aws s3 cp myfile.txt s3://my-bucket/ \
  --metadata key1=value1,key2=value2

# Upload directory
aws s3 cp mydir/ s3://my-bucket/mydir/ --recursive

# Upload with server-side encryption
aws s3 cp myfile.txt s3://my-bucket/ \
  --server-side-encryption AES256

# Upload large file (multipart)
aws s3 cp largefile.zip s3://my-bucket/ \
  --storage-class STANDARD_IA
```

#### Using AWS SDK (Python)
```python
import boto3

s3 = boto3.client('s3')

# Upload file
s3.upload_file('myfile.txt', 'my-bucket', 'myfile.txt')

# Upload with metadata
s3.upload_file(
    'myfile.txt',
    'my-bucket',
    'myfile.txt',
    ExtraArgs={
        'Metadata': {'key1': 'value1'},
        'ServerSideEncryption': 'AES256'
    }
)

# Upload from memory
s3.put_object(
    Bucket='my-bucket',
    Key='data.json',
    Body=json.dumps({'key': 'value'}),
    ContentType='application/json'
)
```

### 2. Download Files

```bash
# Download single file
aws s3 cp s3://my-bucket/myfile.txt ./

# Download directory
aws s3 cp s3://my-bucket/mydir/ ./mydir/ --recursive

# Download specific version
aws s3api get-object \
  --bucket my-bucket \
  --key myfile.txt \
  --version-id VERSION_ID \
  myfile.txt
```

### 3. List Files

```bash
# List all objects
aws s3 ls s3://my-bucket/

# List with details
aws s3 ls s3://my-bucket/ --recursive --human-readable

# List specific prefix
aws s3 ls s3://my-bucket/mydir/

# List versions
aws s3api list-object-versions --bucket my-bucket
```

### 4. Set Bucket Policy

```bash
# Create policy file
cat > bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAppAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/app-role"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
EOF

# Apply policy
aws s3api put-bucket-policy \
  --bucket my-bucket \
  --policy file://bucket-policy.json
```

### 5. Configure CORS (for web apps)

```bash
# Create CORS configuration
cat > cors.json <<EOF
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://myapp.com"],
      "AllowedMethods": ["GET", "HEAD", "PUT", "POST"],
      "AllowedHeaders": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}
EOF

# Apply CORS
aws s3api put-bucket-cors \
  --bucket my-bucket \
  --cors-configuration file://cors.json
```

## Common Use Cases

### Use Case 1: Application Data Storage

**Requirements**: Store application files, user uploads

```yaml
# Via GitHub Actions
Action: apply
Environment: prod
Bucket Name: myapp-data-prod
Enable Versioning: true
Enable Encryption: true
Block Public Access: true
Enable Lifecycle Rules: true
```

**Lifecycle Policy**:
```hcl
lifecycle_rules = [
  {
    id      = "optimize-storage"
    enabled = true
    
    transition = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      }
    ]
  }
]
```

**Application Code**:
```python
import boto3

s3 = boto3.client('s3')

# Upload user file
def upload_user_file(user_id, file_path):
    key = f"users/{user_id}/{file_path}"
    s3.upload_file(file_path, 'myapp-data-prod', key)
    return key

# Download user file
def download_user_file(user_id, file_path):
    key = f"users/{user_id}/{file_path}"
    s3.download_file('myapp-data-prod', key, file_path)
```

**Cost**: ~$0.023/GB/month (STANDARD)

### Use Case 2: Static Website Hosting

**Requirements**: Host static website (HTML, CSS, JS)

```yaml
Action: apply
Environment: prod
Bucket Name: mywebsite-com
Enable Versioning: false
Enable Encryption: true
Block Public Access: false  # Allow public read
Enable Lifecycle Rules: false
```

**Additional Configuration**:
```hcl
# Enable website hosting
website = {
  index_document = "index.html"
  error_document = "error.html"
}

# Public read policy
bucket_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::mywebsite-com/*"
    }
  ]
}
```

**Deploy Website**:
```bash
# Build website
npm run build

# Upload to S3
aws s3 sync ./dist/ s3://mywebsite-com/ \
  --delete \
  --cache-control "max-age=31536000"

# Invalidate CloudFront (if using)
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/*"
```

**Cost**: ~$0.023/GB/month + $0.0004/1000 requests

### Use Case 3: Backup Storage

**Requirements**: Store database backups, long-term archives

```yaml
Action: apply
Environment: prod
Bucket Name: myapp-backups-prod
Enable Versioning: true
Enable Encryption: true
Block Public Access: true
Enable Lifecycle Rules: true
```

**Lifecycle Policy**:
```hcl
lifecycle_rules = [
  {
    id      = "archive-backups"
    enabled = true
    
    transition = [
      {
        days          = 7
        storage_class = "STANDARD_IA"
      },
      {
        days          = 30
        storage_class = "GLACIER"
      },
      {
        days          = 90
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    
    expiration = {
      days = 365
    }
  }
]
```

**Backup Script**:
```bash
#!/bin/bash
# Database backup script

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="backup-${DATE}.sql.gz"

# Create backup
pg_dump mydb | gzip > $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE s3://myapp-backups-prod/database/ \
  --storage-class STANDARD_IA

# Clean up local file
rm $BACKUP_FILE

echo "Backup completed: $BACKUP_FILE"
```

**Cost**: 
- First 7 days: ~$0.023/GB/month
- Days 7-30: ~$0.0125/GB/month (STANDARD_IA)
- Days 30-90: ~$0.004/GB/month (GLACIER)
- After 90 days: ~$0.00099/GB/month (DEEP_ARCHIVE)

### Use Case 4: Data Lake

**Requirements**: Store large datasets for analytics

```yaml
Action: apply
Environment: prod
Bucket Name: mycompany-datalake-prod
Enable Versioning: false
Enable Encryption: true
Block Public Access: true
Enable Lifecycle Rules: true
```

**Organization Structure**:
```
s3://mycompany-datalake-prod/
├── raw/              # Raw data ingestion
│   ├── 2026/
│   │   ├── 05/
│   │   │   ├── 16/
│   │   │   │   └── data.parquet
├── processed/        # Processed data
│   ├── customers/
│   ├── orders/
│   └── products/
└── analytics/        # Analytics results
    └── reports/
```

**Lifecycle Policy**:
```hcl
lifecycle_rules = [
  {
    id      = "archive-raw-data"
    enabled = true
    prefix  = "raw/"
    
    transition = [
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
  },
  {
    id      = "intelligent-tiering"
    enabled = true
    prefix  = "processed/"
    
    transition = [
      {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    ]
  }
]
```

**Query with Athena**:
```sql
-- Create external table
CREATE EXTERNAL TABLE customers (
  id INT,
  name STRING,
  email STRING
)
STORED AS PARQUET
LOCATION 's3://mycompany-datalake-prod/processed/customers/';

-- Query data
SELECT * FROM customers WHERE id = 123;
```

**Cost**: Varies by storage class and access patterns

## Bucket Management

### Sync Files

```bash
# Sync local to S3
aws s3 sync ./local-dir/ s3://my-bucket/remote-dir/

# Sync S3 to local
aws s3 sync s3://my-bucket/remote-dir/ ./local-dir/

# Sync with delete
aws s3 sync ./local-dir/ s3://my-bucket/remote-dir/ --delete

# Sync with exclusions
aws s3 sync ./local-dir/ s3://my-bucket/remote-dir/ \
  --exclude "*.tmp" \
  --exclude ".git/*"
```

### Copy Between Buckets

```bash
# Copy single object
aws s3 cp s3://source-bucket/file.txt s3://dest-bucket/file.txt

# Copy directory
aws s3 cp s3://source-bucket/dir/ s3://dest-bucket/dir/ --recursive

# Copy with different storage class
aws s3 cp s3://source-bucket/file.txt s3://dest-bucket/file.txt \
  --storage-class GLACIER
```

### Delete Files

```bash
# Delete single file
aws s3 rm s3://my-bucket/file.txt

# Delete directory
aws s3 rm s3://my-bucket/dir/ --recursive

# Delete specific version
aws s3api delete-object \
  --bucket my-bucket \
  --key file.txt \
  --version-id VERSION_ID

# Delete all versions
aws s3api delete-objects \
  --bucket my-bucket \
  --delete "$(aws s3api list-object-versions \
    --bucket my-bucket \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --output json)"
```

### Monitor Usage

```bash
# Get bucket size
aws s3 ls s3://my-bucket --recursive --summarize

# Get object count
aws s3 ls s3://my-bucket --recursive | wc -l

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=my-bucket Name=StorageType,Value=StandardStorage \
  --start-time 2026-05-01T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 86400 \
  --statistics Average
```

### Enable Notifications

```bash
# Create SNS topic
aws sns create-topic --name s3-notifications

# Configure bucket notification
cat > notification.json <<EOF
{
  "TopicConfigurations": [
    {
      "TopicArn": "arn:aws:sns:us-east-1:123456789012:s3-notifications",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {
              "Name": "prefix",
              "Value": "uploads/"
            }
          ]
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-notification-configuration \
  --bucket my-bucket \
  --notification-configuration file://notification.json
```

## Troubleshooting

### Issue 1: Access Denied

**Symptoms**:
```bash
aws s3 ls s3://my-bucket/
# An error occurred (AccessDenied) when calling the ListObjectsV2 operation
```

**Diagnosis**:
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket my-bucket

# Check IAM permissions
aws iam get-user-policy --user-name myuser --policy-name mypolicy
```

**Solutions**:

1. **Add IAM Permissions**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

2. **Update Bucket Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/myuser"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ]
    }
  ]
}
```

### Issue 2: Bucket Not Empty (Cannot Delete)

**Symptoms**:
```bash
aws s3 rb s3://my-bucket
# remove_bucket failed: s3://my-bucket/ A client error (BucketNotEmpty) occurred
```

**Solutions**:

```bash
# Delete all objects and versions
aws s3 rm s3://my-bucket --recursive

# Delete all versions (if versioning enabled)
aws s3api delete-objects \
  --bucket my-bucket \
  --delete "$(aws s3api list-object-versions \
    --bucket my-bucket \
    --output json \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects \
  --bucket my-bucket \
  --delete "$(aws s3api list-object-versions \
    --bucket my-bucket \
    --output json \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Now delete bucket
aws s3 rb s3://my-bucket
```

### Issue 3: Slow Upload/Download

**Symptoms**:
Large files taking too long to transfer

**Solutions**:

1. **Use Multipart Upload**:
```bash
# AWS CLI automatically uses multipart for files > 8MB
aws s3 cp largefile.zip s3://my-bucket/ \
  --storage-class STANDARD_IA
```

2. **Use S3 Transfer Acceleration**:
```bash
# Enable transfer acceleration
aws s3api put-bucket-accelerate-configuration \
  --bucket my-bucket \
  --accelerate-configuration Status=Enabled

# Upload using acceleration endpoint
aws s3 cp largefile.zip s3://my-bucket/ \
  --endpoint-url https://my-bucket.s3-accelerate.amazonaws.com
```

3. **Parallel Transfers**:
```python
import boto3
from boto3.s3.transfer import TransferConfig

s3 = boto3.client('s3')

# Configure for faster transfers
config = TransferConfig(
    multipart_threshold=1024 * 25,  # 25 MB
    max_concurrency=10,
    multipart_chunksize=1024 * 25,
    use_threads=True
)

s3.upload_file('largefile.zip', 'my-bucket', 'largefile.zip', Config=config)
```

### Issue 4: High Costs

**Diagnosis**:
```bash
# Check storage metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=my-bucket Name=StorageType,Value=StandardStorage \
  --start-time 2026-05-01T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 86400 \
  --statistics Average

# Check request metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name AllRequests \
  --dimensions Name=BucketName,Value=my-bucket \
  --start-time 2026-05-01T00:00:00Z \
  --end-time 2026-05-16T23:59:59Z \
  --period 86400 \
  --statistics Sum
```

**Solutions**:

1. **Implement Lifecycle Policies**:
```hcl
lifecycle_rules = [
  {
    id      = "cost-optimization"
    enabled = true
    
    transition = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
    
    expiration = {
      days = 365
    }
  }
]
```

2. **Use Intelligent Tiering**:
```bash
aws s3api put-object \
  --bucket my-bucket \
  --key myfile.txt \
  --body myfile.txt \
  --storage-class INTELLIGENT_TIERING
```

3. **Delete Unnecessary Data**:
```bash
# Find old files
aws s3 ls s3://my-bucket/ --recursive | \
  awk '$1 < "2025-01-01" {print $4}'

# Delete old files
aws s3 rm s3://my-bucket/old-data/ --recursive
```

4. **Optimize Requests**:
```python
# Bad: Multiple individual requests
for file in files:
    s3.get_object(Bucket='my-bucket', Key=file)

# Good: Batch operations
s3.download_fileobj(Bucket='my-bucket', Key='archive.zip', Fileobj=f)
```

## Best Practices

### 1. Security

✅ **Always enable encryption**
```hcl
enable_encryption = true
```

✅ **Block public access by default**
```hcl
block_public_access = true
```

✅ **Use bucket policies for access control**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/app-role"
      },
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
```

✅ **Enable access logging**
```hcl
enable_logging = true
logging_bucket = "my-logs-bucket"
```

✅ **Use MFA Delete for critical buckets**
```bash
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::123456789012:mfa/user 123456"
```

### 2. Cost Optimization

✅ **Implement lifecycle policies**
```hcl
lifecycle_rules = [
  {
    id      = "archive-old-data"
    enabled = true
    transition = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      }
    ]
  }
]
```

✅ **Use appropriate storage classes**
- **STANDARD**: Frequently accessed
- **STANDARD_IA**: Infrequently accessed (30+ days)
- **INTELLIGENT_TIERING**: Unknown access patterns
- **GLACIER**: Archive (90+ days)
- **DEEP_ARCHIVE**: Long-term archive (180+ days)

✅ **Delete incomplete multipart uploads**
```hcl
lifecycle_rules = [
  {
    id      = "cleanup-uploads"
    enabled = true
    abort_incomplete_multipart_upload_days = 7
  }
]
```

✅ **Monitor and optimize requests**
- Use CloudFront for static content
- Batch operations when possible
- Use S3 Select for filtering

### 3. Data Protection

✅ **Enable versioning for critical data**
```hcl
enable_versioning = true
```

✅ **Implement backup strategy**
```bash
# Cross-region replication
# Regular snapshots
# Test restore procedures
```

✅ **Use Object Lock for compliance**
```bash
aws s3api put-object-lock-configuration \
  --bucket my-bucket \
  --object-lock-configuration \
    'ObjectLockEnabled=Enabled,Rule={DefaultRetention={Mode=GOVERNANCE,Days=30}}'
```

✅ **Monitor for unauthorized access**
```bash
# Enable CloudTrail
# Set up CloudWatch alarms
# Review access logs regularly
```

### 4. Performance

✅ **Use appropriate request patterns**
```python
# Good: List with prefix
s3.list_objects_v2(Bucket='my-bucket', Prefix='2026/05/')

# Bad: List all then filter
objects = s3.list_objects_v2(Bucket='my-bucket')
filtered = [o for o in objects if o['Key'].startswith('2026/05/')]
```

✅ **Optimize object keys**
```
# Good: Distribute load
user-123/file.txt
user-456/file.txt

# Bad: Hot partition
2026/05/16/user-123.txt
2026/05/16/user-456.txt
```

✅ **Use multipart upload for large files**
```python
# Automatic for files > 8MB with boto3
s3.upload_file('largefile.zip', 'my-bucket', 'largefile.zip')
```

✅ **Enable Transfer Acceleration for global users**
```bash
aws s3api put-bucket-accelerate-configuration \
  --bucket my-bucket \
  --accelerate-configuration Status=Enabled
```

### 5. Monitoring

✅ **Enable CloudWatch metrics**
```bash
# Request metrics
aws s3api put-bucket-metrics-configuration \
  --bucket my-bucket \
  --id EntireBucket \
  --metrics-configuration Id=EntireBucket
```

✅ **Set up CloudWatch alarms**
```bash
# Alert on high error rate
aws cloudwatch put-metric-alarm \
  --alarm-name s3-high-4xx-errors \
  --alarm-description "Alert on high 4xx errors" \
  --metric-name 4xxErrors \
  --namespace AWS/S3 \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold
```

✅ **Review access logs**
```bash
# Download logs
aws s3 sync s3://my-logs-bucket/s3-access-logs/ ./logs/

# Analyze with Athena
CREATE EXTERNAL TABLE s3_access_logs (
  bucketowner STRING,
  bucket_name STRING,
  requestdatetime STRING,
  remoteip STRING,
  requester STRING,
  requestid STRING,
  operation STRING,
  key STRING,
  request_uri STRING,
  httpstatus STRING,
  errorcode STRING,
  bytessent BIGINT,
  objectsize BIGINT,
  totaltime STRING,
  turnaroundtime STRING,
  referrer STRING,
  useragent STRING,
  versionid STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = '1',
  'input.regex' = '([^ ]*) ([^ ]*) \\[(.*?)\\] ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) \\\"([^ ]*) ([^ ]*) (- |[^ ]*)\\\" (-|[0-9]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) (\"[^\"]*\") ([^ ]*)(?: ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*))?.*$'
)
LOCATION 's3://my-logs-bucket/s3-access-logs/';
```

## Maintenance Tasks

### Daily Tasks
- [ ] Monitor CloudWatch alarms
- [ ] Review access logs for anomalies
- [ ] Check storage metrics

### Weekly Tasks
- [ ] Review bucket policies
- [ ] Check lifecycle rule effectiveness
- [ ] Monitor costs
- [ ] Review versioning usage

### Monthly Tasks
- [ ] Audit IAM permissions
- [ ] Review and optimize storage classes
- [ ] Test backup/restore procedures
- [ ] Clean up old data
- [ ] Review replication status

### Quarterly Tasks
- [ ] Security audit
- [ ] Cost optimization review
- [ ] Update documentation
- [ ] Review compliance requirements
- [ ] Test disaster recovery

## Cleanup and Destroy

### Before Destroying

⚠️ **CRITICAL**: S3 bucket deletion is **PERMANENT** and **IRREVERSIBLE**. All data will be lost.

**Pre-Destruction Checklist**:
- [ ] **Backup all important data** (download or replicate)
- [ ] Verify no applications are using the bucket
- [ ] Check for cross-account access
- [ ] Review bucket policies and dependencies
- [ ] Notify team members
- [ ] Document bucket configuration for future reference
- [ ] Export CloudWatch metrics if needed

### Method 1: Via GitHub Actions (Recommended)

1. **Navigate to GitHub Actions**
   ```
   Repository → Actions → S3 Infrastructure
   ```

2. **Click "Run workflow"**

3. **Configure destroy settings**:
   ```yaml
   Action: destroy
   Environment: dev  # or staging/prod
   Bucket Name: my-app-data-dev-20260516  # Must match existing
   Enable Versioning: true  # Must match existing
   Enable Encryption: true  # Must match existing
   Block Public Access: true  # Must match existing
   Enable Lifecycle Rules: false  # Must match existing
   ```

4. **Important**: Bucket must be empty
   - GitHub Actions will fail if bucket contains objects
   - You must empty the bucket first (see below)

5. **Review destroy plan**
   - Workflow will show what will be destroyed
   - Verify the bucket name is correct

6. **Approve and execute** (for prod environment)
   - Production requires manual approval
   - **Double-check bucket name** before approving

7. **Monitor destruction**
   - Watch the workflow logs
   - Verify successful completion

**Expected Output**:
```
✅ S3 Bucket Destroyed Successfully!

Destroyed Resources:
- Bucket: my-app-data-dev-20260516
- Bucket Policy: Deleted
- Lifecycle Rules: Deleted
- Replication Configuration: Deleted

Cleanup completed in 1 minute.
```

### Method 2: Via AWS CLI

#### Step 1: Backup Data (CRITICAL)

```bash
BUCKET_NAME="my-app-data-prod"

# Download entire bucket
aws s3 sync s3://$BUCKET_NAME/ ./backup-$(date +%Y%m%d)/

# Or create a backup in another bucket
aws s3 sync s3://$BUCKET_NAME/ s3://backup-bucket/$BUCKET_NAME/

# Verify backup
ls -lh ./backup-$(date +%Y%m%d)/
```

#### Step 2: Empty the Bucket

**Option A: Delete All Objects and Versions**
```bash
# Delete all objects (non-versioned bucket)
aws s3 rm s3://$BUCKET_NAME/ --recursive

# For versioned buckets, delete all versions
aws s3api delete-objects \
  --bucket $BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
    --bucket $BUCKET_NAME \
    --output json \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Delete all delete markers
aws s3api delete-objects \
  --bucket $BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
    --bucket $BUCKET_NAME \
    --output json \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"

# Verify bucket is empty
aws s3 ls s3://$BUCKET_NAME/ --recursive
```

**Option B: Using Script for Large Buckets**
```bash
#!/bin/bash
# empty-bucket.sh

BUCKET_NAME="$1"

echo "Emptying bucket: $BUCKET_NAME"

# Delete all object versions
aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --output json \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' | \
  jq -r '.[] | "\(.Key)\t\(.VersionId)"' | \
  while IFS=$'\t' read -r key version; do
    echo "Deleting: $key (version: $version)"
    aws s3api delete-object \
      --bucket $BUCKET_NAME \
      --key "$key" \
      --version-id "$version"
  done

# Delete all delete markers
aws s3api list-object-versions \
  --bucket $BUCKET_NAME \
  --output json \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' | \
  jq -r '.[] | "\(.Key)\t\(.VersionId)"' | \
  while IFS=$'\t' read -r key version; do
    echo "Deleting marker: $key (version: $version)"
    aws s3api delete-object \
      --bucket $BUCKET_NAME \
      --key "$key" \
      --version-id "$version"
  done

echo "Bucket emptied successfully"
```

Usage:
```bash
chmod +x empty-bucket.sh
./empty-bucket.sh my-app-data-prod
```

#### Step 3: Delete Bucket

```bash
# Delete the bucket
aws s3 rb s3://$BUCKET_NAME

# Or force delete (empties and deletes)
aws s3 rb s3://$BUCKET_NAME --force

# Verify deletion
aws s3 ls | grep $BUCKET_NAME
```

#### Step 4: Clean Up Related Resources

```bash
# Delete bucket policy (if not auto-deleted)
aws s3api delete-bucket-policy --bucket $BUCKET_NAME

# Delete lifecycle configuration
aws s3api delete-bucket-lifecycle --bucket $BUCKET_NAME

# Delete replication configuration
aws s3api delete-bucket-replication --bucket $BUCKET_NAME

# Delete CORS configuration
aws s3api delete-bucket-cors --bucket $BUCKET_NAME

# Delete website configuration
aws s3api delete-bucket-website --bucket $BUCKET_NAME

# Delete logging configuration
aws s3api put-bucket-logging \
  --bucket $BUCKET_NAME \
  --bucket-logging-status {}

# Delete encryption configuration
aws s3api delete-bucket-encryption --bucket $BUCKET_NAME
```

### Method 3: Via Terraform (Direct)

```bash
# Navigate to environment directory
cd terraform/environments/dev/s3

# IMPORTANT: Empty bucket first
aws s3 rm s3://my-bucket/ --recursive

# Review what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy -auto-approve

# Or destroy specific resource
terraform destroy -target=module.s3
```

### Partial Cleanup

#### Archive Instead of Delete

```bash
# Move to archive bucket instead of deleting
aws s3 sync s3://my-app-data/ s3://archive-bucket/my-app-data-$(date +%Y%m%d)/

# Apply lifecycle policy to archive bucket
cat > lifecycle-archive.json <<EOF
{
  "Rules": [
    {
      "Id": "archive-to-glacier",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 0,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket archive-bucket \
  --lifecycle-configuration file://lifecycle-archive.json
```

#### Delete Old Data Only

```bash
# Delete objects older than 90 days
aws s3api list-objects-v2 \
  --bucket $BUCKET_NAME \
  --query "Contents[?LastModified<='$(date -d '90 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z)'].Key" \
  --output text | \
  xargs -I {} aws s3 rm s3://$BUCKET_NAME/{}

# Or use lifecycle policy
cat > lifecycle-cleanup.json <<EOF
{
  "Rules": [
    {
      "Id": "delete-old-data",
      "Status": "Enabled",
      "Expiration": {
        "Days": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://lifecycle-cleanup.json
```

### Verify Cleanup

```bash
# Verify bucket is deleted
aws s3 ls | grep $BUCKET_NAME

# Check for orphaned resources
# (Usually auto-deleted with bucket)

# Verify no CloudWatch alarms remain
aws cloudwatch describe-alarms \
  --alarm-name-prefix $BUCKET_NAME

# Delete orphaned alarms
aws cloudwatch delete-alarms \
  --alarm-names alarm-name-1 alarm-name-2
```

### Cost Savings After Destruction

**Immediate Savings**:
- Storage charges stop immediately
- Request charges stop
- Data transfer charges stop
- Replication charges stop

**Example**:
```
Before: 1TB STANDARD storage = ~$23/month
After: $0/month
Savings: $23/month or $276/year

Before: 1TB GLACIER storage = ~$4/month
After: $0/month
Savings: $4/month or $48/year
```

### Troubleshooting Destroy Issues

#### Issue: Bucket Not Empty

**Error**: "The bucket you tried to delete is not empty"

**Solution**:
```bash
# Check what's in the bucket
aws s3 ls s3://$BUCKET_NAME/ --recursive

# For versioned buckets, check versions
aws s3api list-object-versions --bucket $BUCKET_NAME

# Empty the bucket completely
aws s3 rm s3://$BUCKET_NAME/ --recursive

# Delete all versions
aws s3api delete-objects \
  --bucket $BUCKET_NAME \
  --delete "$(aws s3api list-object-versions \
    --bucket $BUCKET_NAME \
    --output json \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

# Now delete bucket
aws s3 rb s3://$BUCKET_NAME
```

#### Issue: Access Denied

**Error**: "Access Denied" when trying to delete

**Solution**:
```bash
# Check bucket policy
aws s3api get-bucket-policy --bucket $BUCKET_NAME

# Check your IAM permissions
aws iam get-user-policy --user-name your-user --policy-name your-policy

# If bucket has MFA Delete enabled
aws s3api delete-object \
  --bucket $BUCKET_NAME \
  --key myfile.txt \
  --mfa "arn:aws:iam::123456789012:mfa/user 123456"
```

#### Issue: Bucket Has Replication

**Error**: "Cannot delete bucket with replication enabled"

**Solution**:
```bash
# Disable replication first
aws s3api delete-bucket-replication --bucket $BUCKET_NAME

# Then delete bucket
aws s3 rb s3://$BUCKET_NAME --force
```

#### Issue: Bucket Has Object Lock

**Error**: "Cannot delete bucket with Object Lock enabled"

**Solution**:
```bash
# Object Lock cannot be disabled once enabled
# You must wait for retention period to expire
# Or delete objects individually after retention expires

# Check Object Lock configuration
aws s3api get-object-lock-configuration --bucket $BUCKET_NAME

# For governance mode, you can bypass with permissions
aws s3api delete-object \
  --bucket $BUCKET_NAME \
  --key myfile.txt \
  --bypass-governance-retention
```

### Emergency Recovery

If you accidentally deleted a bucket:

#### Within 24 Hours (Versioning Enabled)

```bash
# If versioning was enabled, you might recover from delete markers
# Contact AWS Support immediately for assistance
```

#### From Backup

```bash
# Restore from backup
aws s3 sync ./backup-20260516/ s3://new-bucket-name/

# Or from backup bucket
aws s3 sync s3://backup-bucket/my-app-data/ s3://new-bucket-name/
```

#### From Replication

```bash
# If replication was enabled, restore from replica bucket
aws s3 sync s3://replica-bucket/ s3://new-bucket-name/
```

### Best Practices for Safe Deletion

✅ **Always backup before deleting**
```bash
aws s3 sync s3://my-bucket/ ./backup/
```

✅ **Use lifecycle policies instead of manual deletion**
```hcl
lifecycle_rules = [
  {
    id      = "auto-cleanup"
    enabled = true
    expiration = {
      days = 90
    }
  }
]
```

✅ **Enable versioning for critical buckets**
```hcl
enable_versioning = true
```

✅ **Test deletion in dev environment first**
```bash
# Test in dev
aws s3 rb s3://dev-bucket --force

# Then apply to prod
aws s3 rb s3://prod-bucket --force
```

✅ **Use bucket policies to prevent accidental deletion**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:DeleteBucket",
      "Resource": "arn:aws:s3:::my-critical-bucket"
    }
  ]
}
```

✅ **Document bucket contents before deletion**
```bash
# Generate inventory
aws s3 ls s3://my-bucket/ --recursive > bucket-inventory.txt

# Get total size
aws s3 ls s3://my-bucket/ --recursive --summarize
```

## Additional Resources

- [Amazon S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

## Support

For issues or questions:
- Check [Troubleshooting](#troubleshooting) section
- Review GitHub Actions workflow logs
- Check AWS CloudWatch logs
- Review S3 access logs
- Contact DevOps team

---

**Last Updated**: May 2026
