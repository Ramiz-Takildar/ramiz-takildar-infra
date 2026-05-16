# ============================================================================
# S3 Bucket Module - Variables
# ============================================================================
# This file defines all input variables for the S3 module.
# Variables are organized by category for better readability.
# ============================================================================

# ============================================================================
# General Configuration
# ============================================================================

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters, start and end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "bucket_name_prefix" {
  description = "Prefix to add to bucket name (useful for environment separation)"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even if it contains objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Versioning Configuration
# ============================================================================

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete for versioned objects"
  type        = bool
  default     = false
}

# ============================================================================
# Encryption Configuration
# ============================================================================

variable "kms_master_key_id" {
  description = "KMS key ID for bucket encryption (leave empty for AES256)"
  type        = string
  default     = ""
}

variable "enable_bucket_key" {
  description = "Enable S3 Bucket Keys for SSE-KMS"
  type        = bool
  default     = true
}

# ============================================================================
# Public Access Block Configuration
# ============================================================================

variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

# ============================================================================
# Bucket Policy Configuration
# ============================================================================

variable "bucket_policy" {
  description = "Custom bucket policy JSON"
  type        = string
  default     = ""
}

variable "enforce_ssl" {
  description = "Enforce SSL/TLS for all bucket operations"
  type        = bool
  default     = true
}

# ============================================================================
# Lifecycle Configuration
# ============================================================================

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id      = string
    enabled = optional(bool)
    filter = optional(object({
      prefix = optional(string)
      tags   = optional(map(string))
    }))
    transition = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })))
    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_transition = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })))
    noncurrent_version_expiration = optional(object({
      noncurrent_days = number
    }))
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = []
}

# ============================================================================
# Logging Configuration
# ============================================================================

variable "enable_logging" {
  description = "Enable access logging for the bucket"
  type        = bool
  default     = false
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = ""
}

# ============================================================================
# CORS Configuration
# ============================================================================

variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []
}

# ============================================================================
# Website Configuration
# ============================================================================

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "website_index_document" {
  description = "Index document for website"
  type        = string
  default     = "index.html"
}

variable "website_error_document" {
  description = "Error document for website"
  type        = string
  default     = "error.html"
}

variable "website_routing_rules" {
  description = "List of routing rules for website"
  type = list(object({
    condition = object({
      key_prefix_equals               = optional(string)
      http_error_code_returned_equals = optional(string)
    })
    redirect = object({
      host_name               = optional(string)
      http_redirect_code      = optional(string)
      protocol                = optional(string)
      replace_key_prefix_with = optional(string)
      replace_key_with        = optional(string)
    })
  }))
  default = []
}

# ============================================================================
# Object Lock Configuration
# ============================================================================

variable "enable_object_lock" {
  description = "Enable object lock for the bucket (requires versioning)"
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Object lock retention mode (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "Object lock mode must be either GOVERNANCE or COMPLIANCE."
  }
}

variable "object_lock_days" {
  description = "Number of days for object lock retention"
  type        = number
  default     = null
}

variable "object_lock_years" {
  description = "Number of years for object lock retention"
  type        = number
  default     = null
}

# ============================================================================
# Replication Configuration
# ============================================================================

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_role_arn" {
  description = "IAM role ARN for replication"
  type        = string
  default     = ""
}

variable "replication_destination_bucket" {
  description = "Destination bucket ARN for replication"
  type        = string
  default     = ""
}

variable "replication_storage_class" {
  description = "Storage class for replicated objects"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "REDUCED_REDUNDANCY", "STANDARD_IA", "ONEZONE_IA", "INTELLIGENT_TIERING", "GLACIER", "DEEP_ARCHIVE"], var.replication_storage_class)
    error_message = "Invalid storage class for replication."
  }
}

variable "replication_kms_key_id" {
  description = "KMS key ID for replication encryption"
  type        = string
  default     = ""
}

variable "replication_delete_marker_replication" {
  description = "Enable delete marker replication"
  type        = bool
  default     = false
}

# ============================================================================
# Intelligent Tiering Configuration
# ============================================================================

variable "enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering"
  type        = bool
  default     = false
}

variable "intelligent_tiering_archive_days" {
  description = "Days before moving to Archive Access tier"
  type        = number
  default     = 90
}

variable "intelligent_tiering_deep_archive_days" {
  description = "Days before moving to Deep Archive Access tier"
  type        = number
  default     = 180
}

# ============================================================================
# Notification Configuration
# ============================================================================

variable "lambda_notifications" {
  description = "List of Lambda function notifications"
  type = list(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
  }))
  default = []
}

variable "sns_notifications" {
  description = "List of SNS topic notifications"
  type = list(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}

variable "sqs_notifications" {
  description = "List of SQS queue notifications"
  type = list(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}

# ============================================================================
# Metrics Configuration
# ============================================================================

variable "enable_metrics" {
  description = "Enable CloudWatch metrics for the bucket"
  type        = bool
  default     = false
}

# ============================================================================
# Inventory Configuration
# ============================================================================

variable "enable_inventory" {
  description = "Enable S3 inventory"
  type        = bool
  default     = false
}

variable "inventory_frequency" {
  description = "Frequency of inventory reports (Daily or Weekly)"
  type        = string
  default     = "Weekly"

  validation {
    condition     = contains(["Daily", "Weekly"], var.inventory_frequency)
    error_message = "Inventory frequency must be either Daily or Weekly."
  }
}

variable "inventory_format" {
  description = "Format of inventory reports (CSV, ORC, or Parquet)"
  type        = string
  default     = "CSV"

  validation {
    condition     = contains(["CSV", "ORC", "Parquet"], var.inventory_format)
    error_message = "Inventory format must be CSV, ORC, or Parquet."
  }
}

variable "inventory_destination_bucket" {
  description = "Destination bucket ARN for inventory reports"
  type        = string
  default     = ""
}

variable "inventory_destination_prefix" {
  description = "Prefix for inventory report objects"
  type        = string
  default     = "inventory"
}

variable "inventory_optional_fields" {
  description = "Optional fields to include in inventory"
  type        = list(string)
  default = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus"
  ]
}

# ============================================================================
# Variable Usage Examples
# ============================================================================
#
# Basic Usage:
# ------------
# bucket_name = "my-application-data"
# enable_versioning = true
# enable_logging = true
# logging_target_bucket = "my-logs-bucket"
#
# With Lifecycle Rules:
# ---------------------
# lifecycle_rules = [
#   {
#     id      = "archive-old-objects"
#     enabled = true
#     transition = [
#       {
#         days          = 30
#         storage_class = "STANDARD_IA"
#       },
#       {
#         days          = 90
#         storage_class = "GLACIER"
#       }
#     ]
#     expiration = {
#       days = 365
#     }
#   }
# ]
#
# With CORS:
# ----------
# cors_rules = [
#   {
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins = ["https://example.com"]
#     allowed_headers = ["*"]
#     max_age_seconds = 3000
#   }
# ]
#
# With Replication:
# -----------------
# enable_replication = true
# replication_role_arn = "arn:aws:iam::123456789012:role/replication-role"
# replication_destination_bucket = "arn:aws:s3:::destination-bucket"
# replication_storage_class = "STANDARD_IA"
#
# ============================================================================
