output "secret_arn" {
  description = "ARN of the secret (use this to scope the External Secrets IAM policy)"
  value       = module.secrets-manager.secret_arn
}

output "secret_id" {
  description = "ID/name of the secret"
  value       = module.secrets-manager.secret_id
}
