#### AWS Secrets Manager ####

# One empty secret per app that has sensitive env vars (e.g. position-tracker, position-simulator).
# The module creates only the secret "shell"; the real value is set out-of-band via
# `aws secretsmanager put-secret-value` / the Console, then synced into the cluster by
# the External Secrets Operator. So no credentials ever live in Git or Terraform state.

module "secrets-manager" {
  source   = "../modules/secrets-manager"
  for_each = toset(var.secrets_manager_apps)

  create_secrets_manager = var.create_secrets_manager
  region                 = var.region
  secret_name            = "${var.project_name}-${var.env}/${each.value}"
  description            = "Sensitive env vars for ${each.value} (${var.env})"
}
