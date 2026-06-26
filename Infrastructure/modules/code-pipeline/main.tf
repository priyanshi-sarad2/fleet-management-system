########     AWS Code Pipeline, Build, Deploy     ########

# Added one lifecycle below for ignoring one redundant change in stage of code-pipeline

resource "aws_codepipeline" "codepipeline" {
  name          = var.pipeline_name
  role_arn      = var.iam_role_arn
  pipeline_type = "V1"

  artifact_store {
    location = var.codepipeline_artifacts_bucket
    type     = "S3"
  }

  # # Add trigger block for Git tags
  # trigger {
  #   provider_type = "CodeStarSourceConnection"

  #   git_configuration {
  #     source_action_name = "PullCode"

  #     push {
  #       tags {
  #         includes = var.env == "uat" ? ["${var.name}-uat-*"] : ["${var.name}-prod-*"]
  #       }
  #     }
  #   }
  # }

  dynamic "stage" {
    for_each = var.enable_source_stage ? [1] : []
    content {
      name = "Source"
      action {
        name             = "PullCode"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source_output"]

        configuration = {
          ConnectionArn    = var.connection_arn
          FullRepositoryId = var.full_repo_path
          BranchName       = var.repo_branch
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_build_stage ? [1] : []
    content {
      name = "Build"
      action {
        name             = "CodeBuild"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = ["build_output"]
        version          = "1"

        configuration = {
          ProjectName = aws_codebuild_project.build_project[0].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_ecr_build_stage ? [1] : []
    content {
      name = "Build"
      action {
        name             = "CodeBuild"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["source_output"]
        output_artifacts = ["build_output"]
        version          = "1"

        configuration = {
          ProjectName = aws_codebuild_project.eks_build_project[0].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_deploy_s3_stage ? [1] : []
    content {
      name = "Deploy"
      action {
        name            = "DeployToS3"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "S3"
        input_artifacts = ["build_output"]
        version         = "1"

        configuration = {
          BucketName = var.s3_bucket_name
          Extract    = "true"
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_cloudfront_invalidate_stage ? [1] : []
    content {
      name = "Invalidate"
      action {
        name            = "InvalidateCloudFront"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build_output"] # dummy required artifact
        version         = "1"

        configuration = {
          ProjectName = aws_codebuild_project.invalidate_cloudfront[0].name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.enable_eks_deploy_stage ? [1] : []
    content {
      name = "EKSDeploy"
      action {
        name            = "DeployToEKS"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        input_artifacts = ["build_output"]
        version         = "1"

        configuration = {
          ProjectName = aws_codebuild_project.eks_deploy_project[0].name
        }
      }
    }
  }

  # lifecycle {
  #   ignore_changes = [
  #     stage[0].action[0].configuration["OutputArtifactFormat"],
  #     stage[1].action[0].configuration["OutputArtifactFormat"],
  #     stage[2].action[0].configuration["OutputArtifactFormat"],
  #     stage[3].action[0].configuration["OutputArtifactFormat"],
  #     stage[4].action[0].configuration["OutputArtifactFormat"]
  #   ]
  # }

}



#####      AWS Code Build Project -> For build stage      ####
resource "aws_codebuild_project" "build_project" {
  count         = var.enable_build_stage ? 1 : 0
  name          = var.build_project_name
  description   = "Build project for ${var.name}-${var.app}"
  service_role  = var.iam_role_arn
  build_timeout = 60

  source {
    type = "CODEPIPELINE"
    # Monorepo: point at the app's buildspec (e.g. k8s-fleetman-webapp-angular/buildspec.yml).
    # Null falls back to CodeBuild's default ./buildspec.yml at the artifact root.
    buildspec = var.build_buildspec
  }

  environment {
    compute_type = var.build_compute_type
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = var.enable_env_vars ? var.env_vars : []
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = lookup(environment_variable.value, "type", "PLAINTEXT")
      }
    }
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}


#####      AWS Code Build Project -> For EKS build stage      ####
resource "aws_codebuild_project" "eks_build_project" {
  count         = var.enable_ecr_build_stage ? 1 : 0
  name          = var.eks_build_project_name
  description   = "EKS Build project for ${var.name}-${var.app}"
  service_role  = var.iam_role_arn
  build_timeout = 60

  source {
    type = "CODEPIPELINE"
    # Monorepo: the buildspec is not at the artifact root, it lives in the
    # service's own folder (k8s-fleetman-<app>/buildspec.yml). Without this,
    # CodeBuild defaults to ./buildspec.yml at the repo root and fails with
    # YAML_FILE_ERROR: YAML file does not exist.
    buildspec = "k8s-fleetman-${var.app}/buildspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
    # Needed for `docker build`/`docker push` in buildspec
    privileged_mode = true

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_uri
    }
    environment_variable {
      name  = "ECR_LOGIN"
      value = var.ecr_login
    }
    environment_variable {
      name  = "APP_NAME"
      value = var.app
    }
    environment_variable {
      name  = "REGION"
      value = var.region
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
}

#####      AWS Code Build Project -> For EKS deploy stage (Helm)      ####
resource "aws_codebuild_project" "eks_deploy_project" {
  count         = var.enable_eks_deploy_stage ? 1 : 0
  name          = var.eks_deploy_project_name
  description   = "EKS Deploy project for ${var.name}-${var.app}"
  service_role  = var.iam_role_arn
  build_timeout = 60

  source {
    type = "CODEPIPELINE"
    # EKS deploy buildspec is stored in the application repo and must be present in the input artifact (build_output)
    buildspec = "eks-deployspec.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }
    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = var.eks_cluster_name
    }
    environment_variable {
      name  = "K8S_NAMESPACE"
      value = var.k8s_namespace
    }
    environment_variable {
      name  = "HELM_RELEASE_NAME"
      value = var.helm_release_name
    }
    environment_variable {
      name  = "HELM_CHART_PATH"
      value = var.helm_chart_path
    }
    environment_variable {
      name  = "HELM_VALUES_FILE"
      value = var.helm_values_file
    }
    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = var.ecr_repository_uri
    }
  }
  artifacts {
    type = "CODEPIPELINE"
  }
}


#####      AWS Code Build Project  -> for Invalidate Cloudfront stage     ####
resource "aws_codebuild_project" "invalidate_cloudfront" {
  count        = var.enable_cloudfront_invalidate_stage ? 1 : 0
  name         = var.cloudfront_project_name
  service_role = var.iam_role_arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "DISTRIBUTION_ID"
      value = var.cloudfront_distribution_id
    }
  }

  source {
    type      = "NO_SOURCE" # No code repo source for this project
    buildspec = <<EOF
version: 0.2
phases:
  build:
    commands:
      - echo "Invalidating CloudFront distribution..."
      - aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'
EOF
  }
  artifacts {
    type = "NO_ARTIFACTS"
  }
}