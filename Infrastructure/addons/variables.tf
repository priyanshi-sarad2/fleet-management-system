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

variable "helm_charts" {
  description = "Helm releases to install, keyed by release name. Empty map installs nothing."
  type = map(object({
    repository    = string
    chart_name    = string
    chart_version = optional(string)
    namespace     = string
    set = optional(list(object({
      name  = string
      value = string
    })), [])
    # Opt-in: when true, the cluster's VPC ID is appended to this chart's set values
    # (discovered dynamically in helm.tf). Charts that don't need it just omit this.
    inject_vpc_id = optional(bool, false)
  }))
  default = {}
}

variable "create_load_balancer_controller" {
  description = "Whether to create the AWS Load Balancer Controller resources (IRSA role, service account, etc.)"
  type        = bool
  default     = false
}

variable "create_aws_cloudwatch_fluent_bit" {
  description = "Whether to create the AWS for Fluent Bit resources (IRSA role, service account, etc.) that ship pod logs to CloudWatch Logs"
  type        = bool
  default     = false
}