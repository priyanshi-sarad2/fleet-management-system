output "arn" {
  description = "ARN of IAM role"
  value       = module.iam_role_for_service_accounts.arn
}

output "name" {
  description = "Name of IAM role"
  value       = module.iam_role_for_service_accounts.name
}

output "iam_policy_arn" {
  description = "ARN of IAM policy created by the underlying module (if any)"
  value       = module.iam_role_for_service_accounts.iam_policy_arn
}

