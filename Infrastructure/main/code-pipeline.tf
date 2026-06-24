########       IAM ROLE        ########
module "iam-custom-policy-codepipeline" {
  source                            = "../modules/iam-module/iam-policy"
  create_iam_policy                 = var.create_codepipeline
  name                              = var.project_name
  app                               = "iam-custom-policy"
  env                               = var.env
  region                            = var.region
  iam_policy_name                   = "${var.project_name}-${var.env}-codepipeline-custom-policy"
  description                       = "Custom policy for CodePipeline"
  attach_cloudwatch_policy          = true # for codepipeline to write logs to CloudWatch
  attach_s3_bucket_policy           = true # so that codepipeline can upload artifacts to the bucket
  attach_cloudfront_access          = false
  attach_iam_role                   = true
  attach_ecr_policy                 = true
  attach_eks_policy                 = true
  attach_codestar_connection_policy = true
  eks_cluster_name                  = "${var.project_name}-eks-cluster"
  account_id                        = var.account_id
}

module "iam-assumable-role-codepipeline" {
  source                    = "../modules/iam-module/iam-role"
  create_iam_role           = var.create_codepipeline
  iam_role_name             = "${var.project_name}-${var.env}-codepipeline"
  iam_role_policy_arns      = var.create_codepipeline ? concat(var.iam_role_policy_arns, [module.iam-custom-policy-codepipeline.arn]) : []
  iam_trusted_role_services = ["codepipeline.amazonaws.com", "codebuild.amazonaws.com"]
  depends_on                = [module.iam-custom-policy-codepipeline]
}



### S3 bucket for CodePipeline artifacts (used by all code pipelines)
module "s3-bucket-codepipeline-artifacts" {
  source            = "../modules/s3"
  name              = var.name
  app               = "codepipeline-artifacts"
  create_bucket     = var.create_codepipeline
  enable_website    = false
  bucket_name       = "${var.name}-codepipeline-artifacts-${var.env}"
  bucket_versioning = false
  lifecycle_rule = [
    {
      id      = "expire-artifacts"
      enabled = true
      expiration = {
        days = 2
      }
      tags = {
        "rule" = "expire-old-artifacts"
      }
    }
  ]
}


########       Shared GitHub connection (one for all pipelines)        ########
resource "aws_codestarconnections_connection" "github" {
  count         = var.create_codepipeline ? 1 : 0
  name          = "${var.project_name}-github"
  provider_type = "GitHub"
}

# with this we are setting the "github_connection_arn" local variable value
locals {
  github_connection_arn = var.create_codepipeline ? aws_codestarconnections_connection.github[0].arn : null
}


########       AWS Code Pipelines    ########

module "code-pipeline" {
  for_each = var.create_codepipeline ? var.codepipeline : {}
  source   = "../modules/code-pipeline"

  name          = var.project_name
  app           = each.key
  env           = var.env
  region        = var.region
  pipeline_name = "${var.project_name}-${each.key}-${var.env}"

  # this will be there for all the pipelines
  enable_source_stage = true

  # these two will be created only if deploy_on_eks is true
  enable_ecr_build_stage  = each.value.deploy_on_eks
  enable_eks_deploy_stage = each.value.deploy_on_eks

  # these three will be created only if deploy_on_eks is false
  enable_build_stage      = !each.value.deploy_on_eks
  enable_deploy_stage     = !each.value.deploy_on_eks
  enable_invalidate_stage = !each.value.deploy_on_eks

  ecr_login          = module.ecr["ecr-${each.key}"].ecr_login_endpoint
  ecr_repository_uri = module.ecr["ecr-${each.key}"].ecr_repository_url

  codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-${var.env}"

  iam_role_arn = var.create_codepipeline ? module.iam-assumable-role-codepipeline.iam_role_arn : ""

  eks_build_project_name  = "${var.project_name}-${each.key}-eks-build-${var.env}"
  eks_deploy_project_name = "${var.project_name}-${each.key}-eks-deploy-${var.env}"

  # kubernetes related variables
  eks_cluster_name  = "${var.project_name}-eks-cluster"
  k8s_namespace     = var.project_k8s_namespace
  helm_release_name = "${var.project_name}-${each.key}-${var.env}"
  helm_chart_path   = "helm-chart"
  helm_values_file  = "helm-chart/values/${var.env}-values.yaml"

  full_repo_path = var.full_repo_path
  repo_branch    = var.repo_branch

  codestart_connection_name = "${each.key}-${var.env}"
  connection_arn            = local.github_connection_arn
}
