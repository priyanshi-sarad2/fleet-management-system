variable "create_iam_policy" {
  type    = bool
  default = false
}
variable "iam_policy_name" {
  type    = string
  default = null
}
variable "description" {
  type    = string
  default = null
}
variable "env" {
  type    = string
  default = null
}
variable "region" {
  type    = string
  default = null
}
variable "account_id" {
  type    = string
  default = null
}
variable "name" {
  type    = string
  default = null
}
variable "app" {
  type    = string
  default = null
}
variable "attach_cloudwatch_policy" {
  type    = bool
  default = false
}
variable "attach_rds_policy" {
  type    = bool
  default = false
}
variable "attach_s3_bucket_policy" {
  type    = bool
  default = false
}
variable "attach_cloudfront_access" {
  type    = bool
  default = false
}
variable "attach_lambda_access" {
  type    = bool
  default = false
}
variable "attach_iam_role" {
  type    = bool
  default = false
}
variable "attach_ecr_policy" {
  type    = bool
  default = false
}
variable "attach_ecs_policy" {
  type    = bool
  default = false
}

variable "attach_eks_policy" {
  type    = bool
  default = false
}

variable "attach_codestar_connection_policy" {
  description = "Attach codestar-connections/codeconnections UseConnection permission (for CodePipeline GitHub source)"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  type    = string
  default = null
}
variable "database_name" {
  type    = string
  default = null
}
# variable "s3_bucket_names" {
#   type = list(string)
#     default = []
# }
variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN(s) the role may invalidate. Accepts a single ARN (string) or a list of ARNs."
  type        = any
  default     = null
}