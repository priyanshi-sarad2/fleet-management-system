########     IAM Role     ########

locals {
  # Default trust policy: allow AWS services (e.g., CodePipeline) to assume the role.
  # Cast to map to keep types consistent with the override case.
  default_trust_policy_permissions = tomap({
    ServiceAssumeRole = {
      # Use `tolist(...)` so Terraform treats this as list(string) (not a tuple),
      # keeping it type-compatible with caller-provided values.
      actions = tolist([
        "sts:AssumeRole",
        "sts:TagSession",
      ])
      principals = tolist([
        {
          type        = "Service"
          identifiers = tolist(var.iam_trusted_role_services)
        }
      ])
      # Keep shape consistent with IRSA/OIDC trust statements which include `condition`.
      # Use null here so Terraform can type-coerce it to the correct list(object(...)) when needed.
      condition = null
    }
  })
}

module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.3"

  create          = var.create_iam_role
  name            = var.iam_role_name
  use_name_prefix = false

  # Trust policy:
  # - default: trust the requested AWS services to assume the role (e.g., codepipeline.amazonaws.com)
  # - override: callers can pass `iam_trust_policy_permissions` for cases like IRSA (Federated/OIDC)
  trust_policy_permissions = var.iam_trust_policy_permissions != null ? tomap(var.iam_trust_policy_permissions) : local.default_trust_policy_permissions

  # Attach all policy ARNs (convert list -> map required by module)
  policies = { for idx, arn in var.iam_role_policy_arns : "policy_${idx}" => arn }
}




/*
  Truested Role Entities:
    - In IAM, "trusted services" are entities (such as AWS services or other IAM roles) that are allowed to assume 
      a role. When a service is trusted to assume the role, it means that the service is authorized to perform 
      actions on your behalf, using the permissions associated with that role.

    - In pipeline case, code-pipeline is the principal that does actions using this role.
*/