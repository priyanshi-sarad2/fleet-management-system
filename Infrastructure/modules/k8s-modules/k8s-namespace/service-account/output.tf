output "service_account_name" {
  description = "The name of the created service account"
  value       = try(kubernetes_service_account.service_account[0].metadata[0].name, null)
}
