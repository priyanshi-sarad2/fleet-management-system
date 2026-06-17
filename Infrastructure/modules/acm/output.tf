output "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate (use this in CloudFront / ALB / etc.)"
  value       = module.acm.acm_certificate_arn
}

output "acm_certificate_domain_validation_options" {
  description = "Domain validation options created by the ACM certificate"
  value       = module.acm.acm_certificate_domain_validation_options
}
