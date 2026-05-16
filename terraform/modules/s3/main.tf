# ============================================================================
# S3 Bucket Module - Main Configuration
# ============================================================================
# This module creates S3 buckets with enterprise-grade features:
# - Versioning
# - Encryption (AES256 or KMS)
# - Lifecycle policies
# - Bucket policies
# - Access logging
# - CORS configuration
# - Replication
# - Object lock
# - Public access block
# - Intelligent tiering
#
# Security Features:
# - Encryption at rest (default)
# - Public access blocked (default)
# - SSL/TLS enforcement
# - Bucket policies
# - Access logging
# ============================================================================

# ============================================================================
# Local Variables
# ============================================================================

locals {
  bucket_name = var.bucket_name_prefix != "" ? "${var.bucket_name_prefix}-${var.bucket_name}" : var.bucket_name
  
  # Default lifecycle rules
  default_lifecycle_rules = var.enable_intelligent_tiering ? [
    {
      id      = "intelligent-tiering"
      enabled = true
      transition = [
        {
          days          = 0
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
    }
  ] : []

  # Merge default and custom lifecycle rules
  lifecycle_rules = concat(local.default_lifecycle_rules, var.lifecycle_rules)
}

# ============================================================================
# S3 Bucket
# ============================================================================

# Create S3 bucket
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = local.bucket_name
    }
  )
}

# ============================================================================
# Bucket Versioning
# ============================================================================

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

# ============================================================================
# Server-Side Encryption
# ============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_master_key_id != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_master_key_id != "" ? var.kms_master_key_id : null
    }
    bucket_key_enabled = var.kms_master_key_id != "" ? var.enable_bucket_key : false
  }
}

# ============================================================================
# Public Access Block
# ============================================================================

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# ============================================================================
# Bucket Policy
# ============================================================================

resource "aws_s3_bucket_policy" "this" {
  count = var.bucket_policy != "" || var.enforce_ssl ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy != "" ? var.bucket_policy : data.aws_iam_policy_document.ssl_only[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# SSL/TLS enforcement policy
data "aws_iam_policy_document" "ssl_only" {
  count = var.enforce_ssl && var.bucket_policy == "" ? 1 : 0

  statement {
    sid    = "EnforceSSLOnly"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# ============================================================================
# Lifecycle Configuration
# ============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(local.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = local.lifecycle_rules

    content {
      id     = rule.value.id
      status = lookup(rule.value, "enabled", true) ? "Enabled" : "Disabled"

      # Filter
      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []

        content {
          prefix = lookup(filter.value, "prefix", null)

          dynamic "tag" {
            for_each = lookup(filter.value, "tags", {})

            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      # Transitions
      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])

        content {
          days          = lookup(transition.value, "days", null)
          date          = lookup(transition.value, "date", null)
          storage_class = transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []

        content {
          days                         = lookup(expiration.value, "days", null)
          date                         = lookup(expiration.value, "date", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])

        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      # Abort incomplete multipart upload
      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload_days", null) != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }
}

# ============================================================================
# Access Logging
# ============================================================================

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix != "" ? var.logging_target_prefix : "${local.bucket_name}/"
}

# ============================================================================
# CORS Configuration
# ============================================================================

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

# ============================================================================
# Website Configuration
# ============================================================================

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.enable_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = var.website_index_document
  }

  error_document {
    key = var.website_error_document
  }

  dynamic "routing_rule" {
    for_each = var.website_routing_rules

    content {
      condition {
        key_prefix_equals = lookup(routing_rule.value.condition, "key_prefix_equals", null)
        http_error_code_returned_equals = lookup(
          routing_rule.value.condition,
          "http_error_code_returned_equals",
          null
        )
      }

      redirect {
        host_name               = lookup(routing_rule.value.redirect, "host_name", null)
        http_redirect_code      = lookup(routing_rule.value.redirect, "http_redirect_code", null)
        protocol                = lookup(routing_rule.value.redirect, "protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.redirect, "replace_key_prefix_with", null)
        replace_key_with        = lookup(routing_rule.value.redirect, "replace_key_with", null)
      }
    }
  }
}

# ============================================================================
# Object Lock Configuration
# ============================================================================

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.enable_object_lock ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    default_retention {
      mode  = var.object_lock_mode
      days  = var.object_lock_days
      years = var.object_lock_years
    }
  }
}

# ============================================================================
# Replication Configuration
# ============================================================================

resource "aws_s3_bucket_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  bucket = aws_s3_bucket.this.id
  role   = var.replication_role_arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {}

    destination {
      bucket        = var.replication_destination_bucket
      storage_class = var.replication_storage_class

      dynamic "encryption_configuration" {
        for_each = var.replication_kms_key_id != "" ? [1] : []

        content {
          replica_kms_key_id = var.replication_kms_key_id
        }
      }
    }

    delete_marker_replication {
      status = var.replication_delete_marker_replication ? "Enabled" : "Disabled"
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# ============================================================================
# Intelligent Tiering Configuration
# ============================================================================

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  count = var.enable_intelligent_tiering ? 1 : 0

  bucket = aws_s3_bucket.this.id
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_deep_archive_days
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_archive_days
  }
}

# ============================================================================
# Bucket Notification
# ============================================================================

resource "aws_s3_bucket_notification" "this" {
  count = length(var.lambda_notifications) > 0 || length(var.sns_notifications) > 0 || length(var.sqs_notifications) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = var.lambda_notifications

    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }

  dynamic "topic" {
    for_each = var.sns_notifications

    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = lookup(topic.value, "filter_prefix", null)
      filter_suffix = lookup(topic.value, "filter_suffix", null)
    }
  }

  dynamic "queue" {
    for_each = var.sqs_notifications

    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }
}

# ============================================================================
# Bucket Metric
# ============================================================================

resource "aws_s3_bucket_metric" "this" {
  count = var.enable_metrics ? 1 : 0

  bucket = aws_s3_bucket.this.id
  name   = "EntireBucket"
}

# ============================================================================
# Bucket Inventory
# ============================================================================

resource "aws_s3_bucket_inventory" "this" {
  count = var.enable_inventory ? 1 : 0

  bucket = aws_s3_bucket.this.id
  name   = "EntireBucketInventory"

  included_object_versions = "All"

  schedule {
    frequency = var.inventory_frequency
  }

  destination {
    bucket {
      format     = var.inventory_format
      bucket_arn = var.inventory_destination_bucket
      prefix     = var.inventory_destination_prefix
    }
  }

  optional_fields = var.inventory_optional_fields
}

# ============================================================================
# Outputs
# ============================================================================
# Outputs are defined in outputs.tf
# ============================================================================
