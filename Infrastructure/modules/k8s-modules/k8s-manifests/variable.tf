variable "k8s_manifests_name" {
  description = "metadata.name of the manifest"
  type        = string
}

variable "k8s_manifests_namespace" {
  description = "metadata.namespace. Leave unset (null) for cluster-scoped resources like ClusterSecretStore."
  type        = string
  default     = null
}

variable "k8s_manifests_api_version" {
  description = "apiVersion of the manifest"
  type        = string
}

variable "k8s_manifests_kind" {
  description = "kind of the manifest"
  type        = string
}

variable "k8s_manifests_spec" {
  description = "The spec block of the manifest"
  type        = any
}
