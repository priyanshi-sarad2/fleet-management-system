####   AWS Load Balancer Controller    ####


### Creating service account first for Load Balancer Controller ###
# The namespace is already created for it
# This service account is annotated with the IRSA role ARN so that the Load Balancer Controller can manage Load Balancers.

module "load-balancer-controller-service-account" {
  source = "../modules/k8s-modules/k8s-namespace/service-account"
  count  = var.create_load_balancer_controller ? 1 : 0

  service_account_name = "load-balancer-controller"
  namespace            = var.k8s_namespaces[2]

  # IRSA: link this service account to the IAM role so the Load Balancer Controller can manage Load Balancers
  annotations = {
    "eks.amazonaws.com/role-arn" = module.load-balancer-controller-irsa.arn
  }
}

module "load-balancer-controller-irsa" {
  source = "../modules/iam-module/iam-role-for-service-account"
  create = var.create_load_balancer_controller

  region      = var.region
  description = "IAM role for Load Balancer Controller"
  name        = "${var.project_name}-${var.env}-load-balancer-controller-role"

  oidc_providers = {
    eks = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
      namespace_service_accounts = ["${var.k8s_namespaces[2]}:${var.k8s_namespaces[2]}"]
    }
  }

  attach_load_balancer_controller_policy = true
}