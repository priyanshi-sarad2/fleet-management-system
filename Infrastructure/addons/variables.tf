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

variable "create_project_k8s_namespace" {
  description = "Whether to create the project's Kubernetes namespace"
  type        = bool
  default     = false
}
