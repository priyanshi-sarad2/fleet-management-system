variable "create" {
  description = "Controls if the IAM role for service accounts should be created"
  type        = bool
  default     = true
}

variable "region" {
  description = "Region where select resource(s) will be managed (IAM resources are global). Defaults to provider region"
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the IAM role to create"
  type        = string
}

variable "description" {
  description = "Description for the IAM role"
  type        = string
  default     = null
}

variable "oidc_providers" {
  description = "Map of OIDC providers (provider_arn + namespace_service_accounts) for IRSA trust relationship"
  type        = any
}

variable "attach_ebs_csi_policy" {
  description = "Attach EBS CSI IAM policy to the role"
  type        = bool
  default     = false
}

variable "ebs_csi_kms_cmk_arns" {
  description = "KMS CMK ARNs to allow EBS CSI to manage encrypted volumes"
  type        = list(string)
  default     = []
}

variable "attach_amazon_managed_service_prometheus_policy" {
  description = "Attach the Amazon Managed Service for Prometheus IAM policy to the role"
  type        = bool
  default     = false
}

variable "amazon_managed_service_prometheus_workspace_arns" {
  description = "List of AMP workspace ARNs the role can read from and write to"
  type        = list(string)
  default     = []
}

