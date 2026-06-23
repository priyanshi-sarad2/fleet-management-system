module "iam_policy" {
  source        = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version       = "6.2.3"
  create        = var.create_iam_policy
  name          = var.iam_policy_name
  name_prefix   = null
  description   = var.description

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = flatten([
      # Conditionally add CloudWatch policy statement
      var.attach_cloudwatch_policy ? [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents"
          ]
          Effect   = "Allow"
          # Global for now so CodeBuild can write to /aws/codebuild/* log groups
          # (the previous /ecs/... scope didn't cover CodeBuild's log group).
          Resource = "*"
        }
      ] : [],

      # Conditionally add S3 policy for all buckets
      var.attach_s3_bucket_policy ? [
        {
          Action = [
            "s3:ListBucket",   # To list the contents of the S3 bucket
            "s3:GetObject",    # To read objects from the S3 bucket
            "s3:PutObject",    # To upload objects to the S3 bucket
            "s3:DeleteObject", # To delete objects from the S3 bucket
            "s3:CreateBucket"  # To create new S3 buckets (optional)
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::*",  # Allows access to all buckets in your account
            "arn:aws:s3:::*/*" # Allows access to all objects in all buckets
          ]
        }
      ] : [],

      # Conditionally add CloudFront invalidation access for a specific distribution
      var.attach_cloudfront_access ? [
        {
          Action   = "cloudfront:CreateInvalidation"
          Effect   = "Allow"
          Resource = var.cloudfront_distribution_arn # Restrict to the specific distribution ARN
        }
      ] : [],

      # Conditionally add IAM permissions for role creation and tagging
      var.attach_iam_role ? [
        {
          Action = [
            "iam:CreateRole",       # Allows creating IAM roles
            "iam:TagRole",          # Allows tagging IAM roles
            "iam:AttachRolePolicy", # Allows attaching IAM policies to roles
            "iam:PutRolePolicy"     # Allows adding inline policies to roles
          ]
          Effect   = "Allow"
          Resource = "*" # Applies to all IAM roles
        }
      ] : [],

      # Conditionally add ECR permissions for pushing images
      var.attach_ecr_policy ? [
        {
          Action = [
            "ecr:GetAuthorizationToken",       # To authenticate to the ECR registry
            "ecr:BatchGetImage",               # To pull images from the ECR registry
            "ecr:BatchCheckLayerAvailability", # Check if layers already exist in the repository
            "ecr:PutImage",                    # To push images to the ECR registry
            "ecr:DescribeRepositories",        # To describe ECR repositories
            "ecr:ListImages",                  # To list images in ECR repositories
            "ecr:InitiateLayerUpload",         # To initiate the upload of image layers
            "ecr:UploadLayerPart",             # To upload parts of image layers
            "ecr:CompleteLayerUpload"          # To complete the upload of image layers
          ]
          Effect   = "Allow"
          Resource = "*" # Applies to all ECR repositories
        }
      ] : [],

      # Conditionally add EKS permissions (used by CodeBuild deploy stage to run `aws eks update-kubeconfig`)
      var.attach_eks_policy ? [
        {
          Action = [
            # Required for `aws eks update-kubeconfig` / `aws eks get-token`
            "eks:DescribeCluster"
          ]
          Effect = "Allow"
          Resource = (
            var.eks_cluster_name != null
            ? "arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.eks_cluster_name}"
            : "*"
          )
        },
        {
          # Required by AWS CLI auth flows (`aws eks get-token` uses STS under the hood)
          Action   = ["sts:GetCallerIdentity"]
          Effect   = "Allow"
          Resource = "*"
        }
      ] : [],

      # Conditionally add CodeConnections permission so CodePipeline's Source stage
      # can use the GitHub connection. (Service was renamed CodeStar Connections -> CodeConnections,
      # so both action namespaces are included.)
      var.attach_codestar_connection_policy ? [
        {
          Action = [
            "codestar-connections:UseConnection",
            "codeconnections:UseConnection"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:codestar-connections:${var.region}:${var.account_id}:connection/*",
            "arn:aws:codeconnections:${var.region}:${var.account_id}:connection/*"
          ]
        }
      ] : [],

      # CodeBuild permissions (ALWAYS attached): CodePipeline must be able to start and
      # monitor the CodeBuild projects it triggers in its build/deploy stages.
      [
        {
          Action = [
            "codebuild:StartBuild",
            "codebuild:BatchGetBuilds",
            "codebuild:StopBuild"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:codebuild:${var.region}:${var.account_id}:project/${var.name}-*"
        }
      ],

    ])
  })

  tags = {
    Terraform = "True"
    Project   = var.name
    Service   = var.app
  }
}
