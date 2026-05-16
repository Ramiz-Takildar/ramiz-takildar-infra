# S3 Bucket Module

This Terraform module creates and manages AWS S3 buckets with enterprise-grade features and security best practices.

## Features

- ✅ Versioning with optional MFA delete
- ✅ Server-side encryption (AES256 or KMS)
- ✅ Public access blocking (enabled by default)
- ✅ Bucket policies with SSL/TLS enforcement
- ✅ Lifecycle policies for cost optimization
- ✅ Access logging
- ✅ CORS configuration
- ✅ Static website hosting
- ✅ Object lock for compliance
- ✅ Cross-region replication
- ✅ S3 Intelligent-Tiering
- ✅ Event notifications (Lambda, SNS, SQS)
- ✅ CloudWatch metrics
- ✅ S3 Inventory
- ✅ Comprehensive tagging

## Usage

### Basic Example

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name       = "my-application-data"
  enable_versioning = true
  
  tags = {
    Environment = "production"
    Project     = "web-app"
  }
}
```

### Complete Example with All Features

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  # Basic Configuration
  bucket_name        = "my-application-data"
  bucket_name_prefix = "prod"  # Results in: prod-my-application-data
  force_destroy      = false

  # Versioning
  enable_versioning = true
  enable_mfa_delete = false

  # Encryption
  kms_master_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  enable_bucket_key  = true

  # Public Access Block (recommended to keep all true)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # SSL/TLS Enforcement
  enforce_ssl = true

  # Lifecycle Rules
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 180
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration = {
        days = 365
      }
      noncurrent_version_transition = [
        {
          noncurrent_days = 30
          storage_class   = "STANDARD_IA"
        }
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  # Access Logging
  enable_logging        = true
  logging_target_bucket = "my-logs-bucket"
  logging_target_prefix = "s3-access-logs/"

  # CORS Configuration
  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com", "https://www.example.com"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Intelligent Tiering
  enable_intelligent_tiering         = true
  intelligent_tiering_archive_days   = 90
  intelligent_tiering_deep_archive_days = 180

  # Event Notifications
  lambda_notifications = [
    {
      lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:process-uploads"
      events              = ["s3:ObjectCreated:*"]
      filter_suffix       = ".jpg"
    }
  ]

  # Metrics and Inventory
  enable_metrics    = true
  enable_inventory  = true
  inventory_frequency = "Daily"
  inventory_destination_bucket = "arn:aws:s3:::my-inventory-bucket"

  # Tags
  tags = {
    Environment        = "production"
    Project            = "web-app"
    ManagedBy          = "Terraform"
    DataClassification = "confidential"
  }
}
```

### Static Website Hosting

```hcl
module "s3_website" {
  source = "../../modules/s3"

  bucket_name = "my-website"

  # Website Configuration
  enable_website          = true
  website_index_document  = "index.html"
  website_error_document  = "404.html"

  # Allow public read access for website
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Custom bucket policy for public read
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-website/*"
      }
    ]
  })

  # CORS for website
  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]

  tags = {
    Environment = "production"
    Type        = "website"
  }
}
```

### Cross-Region Replication

```hcl
# Primary bucket
module "s3_primary" {
  source = "../../modules/s3"

  bucket_name       = "my-primary-bucket"
  enable_versioning = true  # Required for replication

  # Replication Configuration
  enable_replication              = true
  replication_role_arn            = aws_iam_role.replication.arn
  replication_destination_bucket  = "arn:aws:s3:::my-replica-bucket"
  replication_storage_class       = "STANDARD_IA"
  replication_kms_key_id          = "arn:aws:kms:us-west-2:123456789012:key/replica-key"
  replication_delete_marker_replication = true

  tags = {
    Environment = "production"
    Region      = "primary"
  }
}

# Replica bucket (in different region)
module "s3_replica" {
  source = "../../modules/s3"
  
  providers = {
    aws = aws.us_west_2
  }

  bucket_name       = "my-replica-bucket"
  enable_versioning = true

  tags = {
    Environment = "production"
    Region      = "replica"
  }
}
```

### Object Lock for Compliance

```hcl
module "s3_compliance" {
  source = "../../modules/s3"

  bucket_name       = "compliance-data"
  enable_versioning = true  # Required for object lock

  # Object Lock Configuration
  enable_object_lock = true
  object_lock_mode   = "COMPLIANCE"  # or "GOVERNANCE"
  object_lock_days   = 365

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
  }
}
```

### Data Lake with Lifecycle Management

```hcl
module "s3_data_lake" {
  source = "../../modules/s3"

  bucket_name = "data-lake-raw"

  # Lifecycle rules for cost optimization
  lifecycle_rules = [
    {
      id      = "raw-data-lifecycle"
      enabled = true
      filter = {
        prefix = "raw/"
      }
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    },
    {
      id      = "processed-data-lifecycle"
      enabled = true
      filter = {
        prefix = "processed/"
      }
      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]
      expiration = {
        days = 730  # Delete after 2 years
      }
    }
  ]

  # Enable intelligent tiering for unknown access patterns
  enable_intelligent_tiering = true

  tags = {
    Environment = "production"
    Purpose     = "data-lake"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket | `string` | n/a | yes |
| bucket_name_prefix | Prefix to add to bucket name | `string` | `""` | no |
| force_destroy | Allow bucket destruction with objects | `bool` | `false` | no |
| enable_versioning | Enable versioning | `bool` | `true` | no |
| enable_mfa_delete | Enable MFA delete | `bool` | `false` | no |
| kms_master_key_id | KMS key ID for encryption | `string` | `""` | no |
| enable_bucket_key | Enable S3 Bucket Keys | `bool` | `true` | no |
| block_public_acls | Block public ACLs | `bool` | `true` | no |
| block_public_policy | Block public policies | `bool` | `true` | no |
| ignore_public_acls | Ignore public ACLs | `bool` | `true` | no |
| restrict_public_buckets | Restrict public buckets | `bool` | `true` | no |
| bucket_policy | Custom bucket policy JSON | `string` | `""` | no |
| enforce_ssl | Enforce SSL/TLS | `bool` | `true` | no |
| lifecycle_rules | Lifecycle rules | `list(object)` | `[]` | no |
| enable_logging | Enable access logging | `bool` | `false` | no |
| logging_target_bucket | Target bucket for logs | `string` | `""` | no |
| cors_rules | CORS rules | `list(object)` | `[]` | no |
| enable_website | Enable static website | `bool` | `false` | no |
| enable_object_lock | Enable object lock | `bool` | `false` | no |
| enable_replication | Enable replication | `bool` | `false` | no |
| enable_intelligent_tiering | Enable intelligent tiering | `bool` | `false` | no |
| tags | Tags to apply | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket regional domain name |
| website_endpoint | Website endpoint (if enabled) |
| s3_uri | S3 URI for the bucket |
| s3_console_url | AWS Console URL |
| bucket_summary | Summary of configuration |

## Storage Classes

| Class | Use Case | Retrieval Time | Cost |
|-------|----------|----------------|------|
| STANDARD | Frequently accessed data | Milliseconds | Highest |
| STANDARD_IA | Infrequently accessed data | Milliseconds | Medium |
| ONEZONE_IA | Infrequent, non-critical data | Milliseconds | Lower |
| INTELLIGENT_TIERING | Unknown access patterns | Milliseconds | Automatic |
| GLACIER | Archive, rarely accessed | Minutes-Hours | Low |
| DEEP_ARCHIVE | Long-term archive | Hours | Lowest |

## Security Best Practices

1. **Encryption**: Always enable encryption (AES256 or KMS)
2. **Public Access**: Keep public access blocked unless required
3. **SSL/TLS**: Enforce SSL/TLS for all operations
4. **Versioning**: Enable versioning for data protection
5. **Logging**: Enable access logging for audit trails
6. **IAM Policies**: Use least privilege access
7. **Bucket Policies**: Restrict access to specific principals
8. **MFA Delete**: Enable for critical buckets
9. **Object Lock**: Use for compliance requirements
10. **Regular Audits**: Review bucket policies and access logs

## Cost Optimization

1. **Lifecycle Policies**: Transition old data to cheaper storage classes
2. **Intelligent Tiering**: Use for unknown access patterns
3. **Delete Old Versions**: Clean up old object versions
4. **Abort Incomplete Uploads**: Clean up incomplete multipart uploads
5. **S3 Analytics**: Use to understand access patterns
6. **Compression**: Compress data before upload
7. **Request Metrics**: Monitor and optimize request patterns

## Common Lifecycle Patterns

### 30-90-365 Pattern (Standard)
```hcl
lifecycle_rules = [
  {
    id      = "standard-lifecycle"
    enabled = true
    transition = [
      { days = 30, storage_class = "STANDARD_IA" },
      { days = 90, storage_class = "GLACIER" },
      { days = 365, storage_class = "DEEP_ARCHIVE" }
    ]
  }
]
```

### Log Retention Pattern
```hcl
lifecycle_rules = [
  {
    id      = "log-retention"
    enabled = true
    expiration = { days = 90 }
    noncurrent_version_expiration = { noncurrent_days = 30 }
  }
]
```

### Backup Pattern
```hcl
lifecycle_rules = [
  {
    id      = "backup-retention"
    enabled = true
    transition = [
      { days = 7, storage_class = "GLACIER" }
    ]
    expiration = { days = 365 }
  }
]
```

## Troubleshooting

### Bucket name already exists
- S3 bucket names are globally unique
- Choose a different name or add a prefix

### Access denied errors
- Check IAM permissions
- Verify bucket policy
- Check public access block settings

### Replication not working
- Ensure versioning is enabled on both buckets
- Verify IAM role has correct permissions
- Check replication configuration

### Website not accessible
- Verify public access settings
- Check bucket policy allows public read
- Ensure website configuration is correct

## License

This module is maintained by the DevOps team and is available under the MIT License.

## Authors

- DevOps Team

## Support

For issues and questions, please contact the DevOps team or create an issue in the repository.
