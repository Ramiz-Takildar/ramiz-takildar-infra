# ============================================================================
# S3 Bucket Module - Outputs
# ============================================================================
# This file defines all output values from the S3 module.
# Outputs are organized by category for better readability.
# ============================================================================

# ============================================================================
# Bucket Outputs
# ============================================================================

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.this.region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.this.hosted_zone_id
}

# ============================================================================
# Website Outputs
# ============================================================================

output "website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_domain" {
  description = "The domain of the website endpoint"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_domain : null
}

# ============================================================================
# Configuration Status Outputs
# ============================================================================

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.enable_versioning
}

output "encryption_enabled" {
  description = "Whether encryption is enabled"
  value       = true
}

output "encryption_type" {
  description = "Type of encryption (AES256 or aws:kms)"
  value       = var.kms_master_key_id != "" ? "aws:kms" : "AES256"
}

output "logging_enabled" {
  description = "Whether access logging is enabled"
  value       = var.enable_logging
}

output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = var.enable_replication
}

output "object_lock_enabled" {
  description = "Whether object lock is enabled"
  value       = var.enable_object_lock
}

output "intelligent_tiering_enabled" {
  description = "Whether intelligent tiering is enabled"
  value       = var.enable_intelligent_tiering
}

# ============================================================================
# Public Access Block Outputs
# ============================================================================

output "public_access_block_configuration" {
  description = "Public access block configuration"
  value = {
    block_public_acls       = var.block_public_acls
    block_public_policy     = var.block_public_policy
    ignore_public_acls      = var.ignore_public_acls
    restrict_public_buckets = var.restrict_public_buckets
  }
}

# ============================================================================
# Summary Output
# ============================================================================

output "bucket_summary" {
  description = "Summary of bucket configuration"
  value = {
    bucket_name                  = aws_s3_bucket.this.id
    bucket_arn                   = aws_s3_bucket.this.arn
    region                       = aws_s3_bucket.this.region
    versioning_enabled           = var.enable_versioning
    encryption_type              = var.kms_master_key_id != "" ? "aws:kms" : "AES256"
    logging_enabled              = var.enable_logging
    replication_enabled          = var.enable_replication
    object_lock_enabled          = var.enable_object_lock
    intelligent_tiering_enabled  = var.enable_intelligent_tiering
    website_enabled              = var.enable_website
    public_access_blocked        = var.block_public_acls && var.block_public_policy
  }
}

# ============================================================================
# Access URLs
# ============================================================================

output "s3_uri" {
  description = "S3 URI for the bucket"
  value       = "s3://${aws_s3_bucket.this.id}"
}

output "s3_console_url" {
  description = "AWS Console URL for the bucket"
  value       = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.this.id}"
}

output "https_url" {
  description = "HTTPS URL for the bucket"
  value       = "https://${aws_s3_bucket.this.bucket_regional_domain_name}"
}

# ============================================================================
# Output Usage Examples
# ============================================================================
#
# Access outputs in root module:
# -------------------------------
# module "s3" {
#   source = "./modules/s3"
#   # ... configuration ...
# }
#
# output "bucket_name" {
#   value = module.s3.bucket_id
# }
#
# output "bucket_arn" {
#   value = module.s3.bucket_arn
# }
#
# Use outputs in other resources:
# --------------------------------
# resource "aws_cloudfront_distribution" "cdn" {
#   origin {
#     domain_name = module.s3.bucket_regional_domain_name
#     origin_id   = "S3-${module.s3.bucket_id}"
#   }
# }
#
# Access in GitHub Actions:
# -------------------------
# - name: Get Bucket Name
#   run: |
#     BUCKET_NAME=$(terraform output -raw bucket_id)
#     echo "Bucket: $BUCKET_NAME"
#
# ============================================================================
