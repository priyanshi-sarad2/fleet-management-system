####     AWS CloudWatch Fluent Bit    ####

### Creating IAM role for IRSA first ###

module "aws-cloudwatch-fluent-bit-irsa" {
  source = "../modules/iam-module/iam-role-for-service-account"
  create = var.create_aws_cloudwatch_fluent_bit

  region      = var.region
  description = "IAM role for AWS CloudWatch Fluent Bit"
  name        = "${var.project_name}-${var.env}-aws-cloudwatch-fluent-bit-role"

  oidc_providers = {
    eks = {
      provider_arn = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
      # namespace:serviceaccount must match the SA created below (amazon-cloudwatch:aws-cloudwatch-fluent-bit)
      namespace_service_accounts = ["${var.k8s_namespaces[3]}:aws-cloudwatch-fluent-bit"]
    }
  }

  create_policy      = true
  policy_name        = "aws-cloudwatch-fluent-bit-policy"
  policy_description = "IAM policy for AWS CloudWatch Fluent Bit"
  permissions = [
    {
      actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:GetLogEvents"]
      resources = ["*"]
    }
  ]
}


## Creating Service Account for AWS CloudWatch Fluent Bit ##
module "aws-cloudwatch-fluent-bit-service-account" {
  source = "../modules/k8s-modules/k8s-namespace/service-account"
  count  = var.create_aws_cloudwatch_fluent_bit ? 1 : 0

  service_account_name = "aws-cloudwatch-fluent-bit"
  namespace            = var.k8s_namespaces[3]

  # IRSA: link this service account to the IAM role so AWS CloudWatch Fluent Bit can read logs from the cluster
  annotations = {
    "eks.amazonaws.com/role-arn" = module.aws-cloudwatch-fluent-bit-irsa.arn
  }
}
