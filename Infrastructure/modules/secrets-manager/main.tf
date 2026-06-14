#### AWS Secrets Manager ####

module "secrets-manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  create      = var.create_secrets_manager
  region      = var.region
  name        = var.secret_name
  description = var.description

  # "Empty by design": AWS requires a value for the first secret version, so we write a throwaway placeholder.
  # `ignore_secret_changes = true` then makes Terraform ignore the value forever, so the REAL value — set
  # out-of-band via `aws secretsmanager put-secret-value` / the Console — is never overwritten by a future apply
  # (and never lands in Git or, beyond this placeholder, in state).
  ignore_secret_changes = true
  secret_string         = jsonencode({ placeholder = "add secrets here" })

  # Allows deleting/recreating the same secret name immediately instead of waiting out the 7–30 day recovery window (handy while iterating).
  recovery_window_in_days = var.recovery_window_in_days
}