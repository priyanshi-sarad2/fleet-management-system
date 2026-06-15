variable "namespace" {
  description = "Name of the Kubernetes namespace to create"
  type        = string
}

variable "project_name" {
  description = "Value for the `project` label"
  type        = string
  default     = ""
}

variable "env" {
  description = "Value for the `env` label"
  type        = string
  default     = ""
}
