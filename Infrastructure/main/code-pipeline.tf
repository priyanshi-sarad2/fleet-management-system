########       IAM ROLE        ########
module "iam_custom_policy_codepipeline" {
  source                   = "../modules/iam-policy"
  create_iam_policy        = var.create_codepipeline
  name                     = var.project_name
  app                      = "iam-custom-policy"
  env                      = var.env
  region                   = var.region
  iam_policy_name          = "${var.project_name}-${var.env}-codepipeline-custom-policy"
  description              = "Custom policy for ECS Task"
  attach_cloudwatch_policy = false
  attach_rds_policy        = false
  attach_s3_bucket_policy  = true
  attach_cloudfront_access = true
  attach_lambda_access     = true
  attach_iam_role          = true
  attach_ecr_policy        = true
  attach_ecs_policy        = false
  attach_eks_policy        = true
  eks_cluster_name         = "${var.project_name}-eks-cluster"
  account_id               = var.account_id
  # s3_bucket_names = ["${var.project_name}-admin-${var.env}", "${var.project_name}-env", "${var.name}-codepipeline-artifacts"]
  # module.cloudfront-distribution-admin is a list due to `count`; make reference safe when disabled
  cloudfront_distribution_arn = var.create_cloudfront_static_admin ? module.cloudfront-distribution-admin[0].cloudfront_distribution_arn : "arn:aws:cloudfront::000000000000:distribution/EXAMPLE"
}

module "iam_assumable_role" {
  source                    = "../modules/iam-role"
  create_iam_role           = var.create_codepipeline
  iam_role_name             = "${var.project_name}-${var.env}-pipeline-role"
  iam_role_policy_arns      = var.create_codepipeline ? concat(var.iam_role_policy_arns, [module.iam_custom_policy_codepipeline.arn]) : []
  iam_trusted_role_services = var.iam_trusted_role_services
  depends_on                = [module.iam_custom_policy_codepipeline]
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
  pipeline_name = "${var.project_name}-${each.key}-${var.env}"

  # this will be there for all the pipelines
  enable_source_stage     = true

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
  
  iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""

  eks_build_project_name  = "${var.project_name}-${each.key}-eks-build-${var.env}"
  eks_deploy_project_name = "${var.project_name}-${each.key}-eks-deploy-${var.env}"
  eks_cluster_name        = "${var.project_name}-eks-cluster"
  k8s_namespace           = var.project_k8s_namespace
  helm_release_name       = "${var.project_name}-${each.key}-${var.env}"
  helm_chart_path         = "helm-chart"
  helm_values_file        = "helm-chart/values/${var.env}-values.yaml"

  full_repo_path = each.value.repo_full_path
  repo_branch    = each.value.repo_branch

  codestart_connection_name   = "${each.key}-${var.env}"
  connection_arn              = local.github_connection_arn
  region                      = var.region
  create_codepipeline_webhook = false
}
