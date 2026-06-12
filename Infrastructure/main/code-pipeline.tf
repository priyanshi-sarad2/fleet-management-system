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


module "s3-bucket-codepipeline-artifacts" {
  source            = "../modules/s3"
  name              = var.name
  app               = "codepipeline-artifacts"
  create_bucket     = var.create_codepipeline
  enable_website    = false
  bucket_name       = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"
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


#######       AWS Code Pipeline for Admin -> ECS deployment        ########
# module "code-pipeline-riddhi-admin" {
#   count                         = var.create_codepipeline ? 1 : 0
#   source                        = "../modules/code-pipeline"
#   name                          = var.project_name
#   app                           = "code-pipeline-${var.app_1}"
#   env                           = var.env
#   pipeline_name                 = "${var.project_name}-${var.app_1}-${var.env}"
#   enable_source_stage           = true
#   enable_build_stage            = true
#   enable_env_vars               = true
#   enable_deploy_stage           = true
#   enable_invalidate_stage       = true
#   enable_ecr_build_stage        = false
#   enable_ecs_deploy_stage       = false
#   codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"

#   iam_role_arn = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""

#   s3_bucket_name              = "${var.project_name}-admin-${var.env}-practice"
#   env_files_s3_bucket         = "${var.project_name}-env-files"
#   env_files_s3_key            = "${var.project_name}-admin/${var.env}/.env"
#   build_project_name          = "${var.project_name}-${var.app_1}-${var.env}"
#   cloudfront_project_name     = "${var.project_name}-${var.app_1}-${var.env}-invalidate-cloudfront"
#   full_repo_path              = var.full_repo_path_admin
#   repo_branch                 = "main"
#   build_compute_type          = "BUILD_GENERAL1_MEDIUM"
#   codestart_connection_name   = "${var.app_1}-${var.env}"
#   connection_arn              = var.codestar_connection_arn
#   cloudfront_distribution_id  = var.create_cloudfront_static_admin ? module.cloudfront-distribution-admin[0].cloudfront_distribution_id : "EXAMPLE"
#   create_codepipeline_webhook = false
#   env_vars                    = var.admin_pipeline_env_vars
#   depends_on = [
#     module.s3-riddhi-admin,
#     module.s3-bucket-codepipeline-artifacts,
#     module.cloudfront-distribution-admin
#   ]
# }


########       AWS Code Pipeline for API -> ECS deployment        ########
module "code-pipeline-riddhi-api" {
  count                         = var.create_codepipeline ? 1 : 0
  source                        = "../modules/code-pipeline"
  name                          = var.project_name
  app                           = "code-pipeline-${var.app_2}"
  env                           = var.env
  pipeline_name                 = "${var.project_name}-${var.app_2}-${var.env}"
  enable_source_stage           = true
  enable_ecr_build_stage        = true
  enable_ecs_deploy_stage       = false
  enable_eks_deploy_stage       = true
  enable_build_stage            = false
  enable_deploy_stage           = false
  enable_invalidate_stage       = false
  app_name                      = var.app_2
  s3_env_bucket                 = "${var.project_name}-env-files"
  s3_env_bucket_path            = "${var.app_2}/${var.env}"
  ecr_login                     = module.ecr-api.ecr_login_endpoint
  ecr_repository_uri            = module.ecr-api.ecr_repository_url
  codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"
  iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
  ecs_build_project_name        = "${var.project_name}-${var.app_2}-ecs-${var.env}"
  eks_deploy_project_name       = "${var.project_name}-${var.app_2}-eks-${var.env}"
  eks_cluster_name              = "${var.project_name}-eks-cluster"
  k8s_namespace                 = var.project_namespace
  helm_release_name             = "${var.project_name}-${var.app_2}-${var.env}"
  helm_chart_path               = "helm-chart"
  helm_values_file              = "helm-chart/values/${var.env}-values.yaml"
  full_repo_path                = var.full_repo_path_api
  repo_branch                   = "main"
  codestart_connection_name     = "${var.app_2}-${var.env}"
  connection_arn                = var.codestar_connection_arn
  region                        = var.region
  create_codepipeline_webhook   = false
}




########       AWS Code Pipeline for auser management  svc-> ECS deployment        ########
module "code-pipeline-riddhi-user-mgmt-svc" {
  count                         = var.create_codepipeline ? 1 : 0
  source                        = "../modules/code-pipeline"
  name                          = var.project_name
  app                           = "codepipeline-${var.app_3}"
  env                           = var.env
  pipeline_name                 = "${var.project_name}-${var.app_3}-${var.env}"
  enable_source_stage           = true
  enable_ecr_build_stage        = true
  enable_ecs_deploy_stage       = false
  enable_eks_deploy_stage       = true
  enable_build_stage            = false
  enable_deploy_stage           = false
  enable_invalidate_stage       = false
  app_name                      = var.app_3
  s3_env_bucket                 = "${var.project_name}-env-files"
  s3_env_bucket_path            = "microservices/user-management-service/${var.env}"
  ecr_login                     = module.ecr-user-mgmt-svc.ecr_login_endpoint
  ecr_repository_uri            = module.ecr-user-mgmt-svc.ecr_repository_url
  codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"
  iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
  ecs_build_project_name        = "${var.project_name}-${var.app_3}-ecs-${var.env}"
  eks_deploy_project_name       = "${var.project_name}-${var.app_3}-eks-${var.env}"
  eks_cluster_name              = "${var.project_name}-eks-cluster"
  k8s_namespace                 = var.project_namespace
  helm_release_name             = "${var.project_name}-${var.app_3}-${var.env}"
  helm_chart_path               = "helm-chart"
  helm_values_file              = "helm-chart/values/${var.env}-values.yaml"
  full_repo_path                = var.full_repo_path_user_mgmt
  repo_branch                   = "main"
  codestart_connection_name     = "${var.app_3}-${var.env}"
  connection_arn                = var.codestar_connection_arn
  region                        = var.region
  create_codepipeline_webhook   = false
}




########       AWS Code Pipeline for workflow management -> ECS deployment        ########
module "code-pipeline-riddhi-workflow-mgmt-svc" {
  count                         = var.create_codepipeline ? 1 : 0
  source                        = "../modules/code-pipeline"
  name                          = var.project_name
  app                           = "codepipeline-${var.app_4}"
  env                           = var.env
  pipeline_name                 = "${var.project_name}-${var.app_4}-${var.env}"
  enable_source_stage           = true
  enable_ecr_build_stage        = true
  enable_ecs_deploy_stage       = false
  enable_eks_deploy_stage       = true
  enable_build_stage            = false
  enable_deploy_stage           = false
  enable_invalidate_stage       = false
  app_name                      = var.app_4
  s3_env_bucket                 = "${var.project_name}-env-files"
  s3_env_bucket_path            = "microservices/workflow-management-service/${var.env}"
  ecr_login                     = module.ecr-workflow-mgmt-svc.ecr_login_endpoint
  ecr_repository_uri            = module.ecr-workflow-mgmt-svc.ecr_repository_url
  codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"
  iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
  ecs_build_project_name        = "${var.project_name}-${var.app_4}-ecs-${var.env}"
  eks_deploy_project_name       = "${var.project_name}-${var.app_4}-eks-${var.env}"
  eks_cluster_name              = "${var.project_name}-eks-cluster"
  k8s_namespace                 = var.project_namespace
  helm_release_name             = "${var.project_name}-${var.app_4}-${var.env}"
  helm_chart_path               = "helm-chart"
  helm_values_file              = "helm-chart/values/${var.env}-values.yaml"
  full_repo_path                = var.full_repo_path_workflow_mgmt
  repo_branch                   = "main"
  codestart_connection_name     = "${var.app_4}-${var.env}"
  connection_arn                = var.codestar_connection_arn
  region                        = var.region
  create_codepipeline_webhook   = false
}




########       AWS Code Pipeline for Notification svc      ########
module "code-pipeline-riddhi-notification-svc" {
  count                         = var.create_codepipeline ? 1 : 0
  source                        = "../modules/code-pipeline"
  name                          = var.project_name
  app                           = "codepipeline-${var.app_5}"
  env                           = var.env
  pipeline_name                 = "${var.project_name}-${var.app_5}-${var.env}"
  enable_source_stage           = true
  enable_ecr_build_stage        = true
  enable_ecs_deploy_stage       = false
  enable_eks_deploy_stage       = true
  enable_build_stage            = false
  enable_deploy_stage           = false
  enable_invalidate_stage       = false
  app_name                      = var.app_5
  s3_env_bucket                 = "${var.project_name}-env-files"
  s3_env_bucket_path            = "microservices/notification-service/${var.env}"
  ecr_login                     = module.ecr-notification-svc.ecr_login_endpoint
  ecr_repository_uri            = module.ecr-notification-svc.ecr_repository_url
  codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice${var.env == "uat" ? "-uat" : ""}"
  iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
  ecs_build_project_name        = "${var.project_name}-${var.app_5}-ecs-${var.env}"
  eks_deploy_project_name       = "${var.project_name}-${var.app_5}-eks-${var.env}"
  eks_cluster_name              = "${var.project_name}-eks-cluster"
  k8s_namespace                 = var.project_namespace
  helm_release_name             = "${var.project_name}-${var.app_5}-${var.env}"
  helm_chart_path               = "helm-chart"
  helm_values_file              = "helm-chart/values/${var.env}-values.yaml"
  full_repo_path                = var.full_repo_path_notification
  repo_branch                   = "main"
  codestart_connection_name     = "${var.app_5}-${var.env}"
  connection_arn                = var.codestar_connection_arn
  region                        = var.region
  create_codepipeline_webhook   = false
}



# ########       AWS Code Pipeline for Document Microservice        ########
# module "code-pipeline-riddhi-document-svc" {
#   count                         = var.create_codepipeline ? 1 : 0
#   source                        = "../modules/code-pipeline"
#   name                          = var.project_name
#   app                           = "codepipeline-${var.app_6}"
#   env                           = var.env
#   pipeline_name                 = "${var.project_name}-${var.app_6}-${var.env}"
#   enable_source_stage           = true
#   enable_build_stage            = true
#   enable_env_vars               = true
#   enable_deploy_stage           = false
#   enable_invalidate_stage       = false
#   enable_ecr_build_stage        = false
#   enable_ecs_deploy_stage       = false
#   codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice"
#   iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
#   build_project_name            = "${var.project_name}-${var.app_6}-${var.env}"
#   full_repo_path                = var.full_repo_path_document_svc
#   repo_branch                   = "main"
#   build_compute_type            = "BUILD_GENERAL1_SMALL"
#   codestart_connection_name     = "${var.app_6}-${var.env}"
#   connection_arn                = var.codestar_connection_arn
#   create_codepipeline_webhook   = false
#   env_vars                      = var.document_svc_pipeline_env_vars
# }


# ########       AWS Code Pipeline for Document Microservice        ########
# module "code-pipeline-riddhi-notification-queue-handler" {
#   count                         = var.create_codepipeline ? 1 : 0
#   source                        = "../modules/code-pipeline"
#   name                          = var.project_name
#   app                           = "codepipeline-${var.app_7}"
#   env                           = var.env
#   pipeline_name                 = "${var.project_name}-${var.app_7}-${var.env}"
#   enable_source_stage           = true
#   enable_build_stage            = true
#   enable_env_vars               = true
#   enable_deploy_stage           = false
#   enable_invalidate_stage       = false
#   enable_ecr_build_stage        = false
#   enable_ecs_deploy_stage       = false
#   codepipeline_artifacts_bucket = "${var.name}-codepipeline-artifacts-practice"
#   iam_role_arn                  = var.create_codepipeline ? module.iam_assumable_role.iam_role_arn : ""
#   build_project_name            = "${var.project_name}-${var.app_7}-${var.env}"
#   full_repo_path                = var.full_repo_path_notification_queue_handler
#   repo_branch                   = "main"
#   build_compute_type            = "BUILD_GENERAL1_MEDIUM"
#   codestart_connection_name     = "${var.app_7}-${var.env}"
#   connection_arn                = var.codestar_connection_arn
#   create_codepipeline_webhook   = false
#   env_vars                      = var.notification_queue_pipeline_env_vars
# }