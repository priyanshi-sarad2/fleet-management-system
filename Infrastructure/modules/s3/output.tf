output "s3_regional_domain_name" {
  description = "The bucket region-specific domain name (for CloudFront origin)."
  value       = module.s3-bucket.s3_bucket_bucket_regional_domain_name
}
output "s3_bucket_id" {
  description = "The name of the bucket."
  value       = module.s3-bucket.s3_bucket_id
}
output "s3_bucket_arn" {
  description = "The ARN of the bucket. Will be of format arn:aws:s3:::bucketname."
  value       = module.s3-bucket.s3_bucket_arn
}