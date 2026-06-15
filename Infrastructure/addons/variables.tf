variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Used to derive the cluster name: <project_name>-eks-cluster"
  type        = string
  default     = "fleetman"
}

variable "env" {
  type    = string
  default = "prod"
}

variable "k8s_namespaces" {
  description = "Namespaces to create in the cluster. Empty list creates none."
  type        = list(string)
  default     = []
}

variable "create_external_secrets_operator" {
  description = "Whether to create the External Secrets Operator resources (IRSA role, service account, etc.)"
  type        = bool
  default     = false
}

# Supplied via the TF_VAR_account_id environment variable (kept out of version control).
variable "account_id" {
  description = "AWS account ID. Provide via the TF_VAR_account_id environment variable."
  type        = string
}
