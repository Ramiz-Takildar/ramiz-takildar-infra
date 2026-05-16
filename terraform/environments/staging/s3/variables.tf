variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Prefix to add to bucket name"
  type        = string
  default     = ""
}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}

variable "kms_master_key_id" {
  description = "KMS key ID for encryption (leave empty for AES256)"
  type        = string
  default     = ""
}

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

variable "enable_logging" {
  description = "Enable access logging"
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
  default     = "logs/"
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type        = any
  default     = []
}

variable "enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering"
  type        = bool
  default     = false
}

variable "enforce_ssl" {
  description = "Enforce SSL for bucket access"
  type        = bool
  default     = true
}

variable "cors_rules" {
  description = "CORS configuration rules"
  type        = any
  default     = []
}

variable "website_configuration" {
  description = "Website configuration"
  type        = any
  default     = null
}

variable "replication_configuration" {
  description = "Replication configuration"
  type        = any
  default     = null
}

variable "object_lock_enabled" {
  description = "Enable object lock"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
