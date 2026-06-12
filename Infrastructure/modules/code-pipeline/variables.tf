variable "env" {
  type = string
}
variable "pipeline_name" {
  description = "Pipeline Name"
  type        = string
}
variable "enable_source_stage" {
  type    = bool
  default = false
}

variable "enable_build_stage" {
  type    = bool
  default = false
}
variable "enable_ecr_build_stage" {
  type    = bool
  default = false
}

variable "enable_deploy_stage" {
  type    = bool
  default = false
}

variable "enable_invalidate_stage" {
  type    = bool
  default = false
}
variable "enable_ecs_deploy_stage" {
  type    = bool
  default = false
}

# Deploy to EKS via CodeBuild (helm/kubectl)
variable "enable_eks_deploy_stage" {
  type    = bool
  default = false
}
variable "enable_env_vars" {
  type    = bool
  default = false
}
variable "env_vars" {
  description = "List of environment variables to pass to the CodeBuild build stage"
  type = list(object({
    name  = string
    value = string
    type  = optional(string, "PLAINTEXT")
  }))
  default = []
}
variable "iam_role_arn" {
  description = "IAM role arn"
  type        = string
}
variable "codepipeline_artifacts_bucket" {
  description = "S3 bucket name"
  type        = string
}
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = null
}
variable "build_project_name" {
  description = "Build project name"
  type        = string
  default     = null
}
variable "cloudfront_project_name" {
  type        = string
  description = "Name of the CloudFront invalidation CodeBuild project"
  default     = null
}
variable "full_repo_path" {
  description = "Full repo path"
  type        = string
}
variable "repo_branch" {
  description = "github repo branch"
  type        = string
}
variable "name" {
  description = "Project Name -> Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}
variable "app" {
  description = "Project app"
  type        = string
  default     = null
}
variable "codestart_connection_name" {
  description = "Codestart connection name"
  type        = string
}
variable "codestart_connection_provider_type" {
  description = "Codestart connection name"
  type        = string
  default     = null
}
variable "cloudfront_distribution_id" {
  description = "Cloudfront distribution ID"
  type        = string
  default     = null
}
variable "aws_secret_id" {
  type    = string
  default = null
}
variable "aws_secret_string" {
  type    = string
  default = null
}
variable "pipeline_webhook_authentication" {
  type    = string
  default = null
}
variable "pipeline_webhook_filter_match" {
  type    = string
  default = null
}
variable "create_codepipeline_webhook" {
  type    = string
  default = null
}
variable "env_files_s3_bucket" {
  type    = string
  default = null
}
variable "env_files_s3_key" {
  type    = string
  default = "null"
}
variable "codestart_connection_gitlab_host_arn" {
  type        = string
  default     = null
  description = "GitLab host ARN (required if connection_arn is not provided)"
}
variable "connection_arn" {
  type        = string
  default     = null
  description = "Existing CodeStar connection ARN to use. If provided, connection will not be created in this module."
}
variable "ecr_login" {
  type    = string
  default = null
}
variable "ecs_build_project_name" {
  type    = string
  default = null
}
variable "ecr_repository_uri" {
  type    = string
  default = null
}
variable "ecs_cluster_name" {
  type    = string
  default = null
}
variable "ecs_service_name" {
  type    = string
  default = null
}

variable "eks_deploy_project_name" {
  description = "CodeBuild project name for EKS deploy stage"
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "EKS cluster name for deploy stage (used by aws eks update-kubeconfig)"
  type        = string
  default     = null
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
  default     = null
}

variable "helm_release_name" {
  description = "Helm release name"
  type        = string
  default     = null
}

variable "helm_chart_path" {
  description = "Path to the Helm chart directory in the source artifact (e.g., helm-chart)"
  type        = string
  default     = "helm-chart"
}

variable "helm_values_file" {
  description = "Values file path relative to repo root (e.g., helm-chart/values/prod-values.yaml)"
  type        = string
  default     = null
}

variable "app_name" {
  description = "Application name (used across build/deploy stages)"
  type        = string
  default     = null
}
variable "build_compute_type" {
  type    = string
  default = null
}
variable "s3_env_bucket" {
  type    = string
  default = null
}
variable "s3_env_bucket_path" {
  type    = string
  default = null
}
variable "region" {
  type        = string
  description = "AWS region where resources are deployed"
  default     = "us-east-1"
}