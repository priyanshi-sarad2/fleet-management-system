output "arn" {
  description = "The ARN assigned by AWS to this policy"
  value       = module.iam_policy.arn
}