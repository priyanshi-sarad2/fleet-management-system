variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
}

variable "helm_repository" {
  description = "Helm chart repository URL"
  type        = string
}

variable "helm_chart_name" {
  description = "Name of the Helm chart"
  type        = string
}

variable "helm_chart_version" {
  description = "Version of the Helm chart (null = latest)"
  type        = string
  default     = null
}

variable "helm_namespace" {
  description = "Namespace to install the release into"
  type        = string
}

variable "helm_set" {
  description = "List of chart value overrides ({ name = ..., value = ... })"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
