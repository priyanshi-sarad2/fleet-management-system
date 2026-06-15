variable "create" {
  description = "Whether to create the service account"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
}

variable "namespace" {
  description = "Namespace the service account is created in"
  type        = string
}

variable "annotations" {
  description = "Annotations for the service account (e.g. eks.amazonaws.com/role-arn for IRSA)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels for the service account"
  type        = map(string)
  default     = {}
}
