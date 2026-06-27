variable "create_iam_role" {
  description = "Whether to create the IAM role or not"
  type        = bool
  default     = false
}
variable "iam_role_name" {
  description = "Iam role name"
  type        = string
  default     = ""
}
variable "iam_role_policy_arns" {
  description = "List of policy ARNs to attach to the IAM role"
  type        = list(string)
  default     = []
}
variable "iam_trusted_role_services" {
  description = "AWS Services that can assume these roles"
  type        = list(string)
  default     = []
}

# Optional: allow callers to provide a fully custom trust policy statement map.
# This is needed for non-service principals like IRSA (Federated/OIDC) trust.
variable "iam_trust_policy_permissions" {
  description = "Optional custom trust policy permissions map (overrides iam_trusted_role_services when set)"
  # Pass-through type (statements can differ between Service trust vs IRSA/OIDC trust).
  # We intentionally keep this flexible and let the upstream IAM module validate structure.
  type    = map(any)
  default = null
}