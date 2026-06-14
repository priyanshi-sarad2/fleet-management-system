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
