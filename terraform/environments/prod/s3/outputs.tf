output "bucket_id" {
  description = "The name of the bucket"
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.s3.bucket_arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = module.s3.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = module.s3.bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = module.s3.bucket_website_endpoint
}

output "bucket_website_domain" {
  description = "The domain of the website endpoint"
  value       = module.s3.bucket_website_domain
}
