#### AWS Secrets Manager ####

module "secrets-manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  create      = var.create_secrets_manager
  region      = var.region
  name        = var.secret_name
  description = var.description

  # Empty secret: no `secret_string` is passed, so the module creates the
  # secret shell only (no version). The real value is set out-of-band via
  # `aws secretsmanager put-secret-value` / the Console.
  # `ignore_secret_changes` makes sure a future apply never overwrites that
  # manually-set value.
  ignore_secret_changes = true

  # Allows deleting/recreating the same secret name immediately instead of
  # waiting out the 7–30 day recovery window (handy while iterating).
  recovery_window_in_days = var.recovery_window_in_days
}