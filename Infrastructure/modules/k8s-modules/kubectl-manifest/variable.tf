variable "api_version" {
  description = "apiVersion of the manifest (e.g. external-secrets.io/v1)"
  type        = string
}

variable "kind" {
  description = "kind of the manifest (e.g. ClusterSecretStore)"
  type        = string
}

variable "name" {
  description = "metadata.name of the manifest"
  type        = string
}

variable "namespace" {
  description = "metadata.namespace. Leave null for cluster-scoped resources."
  type        = string
  default     = null
}

variable "spec" {
  description = "The spec block of the manifest"
  type        = any
  default     = null
}
