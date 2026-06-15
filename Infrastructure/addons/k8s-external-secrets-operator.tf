####   Kubernetes External Secrets Operator    ####

### Creating IAM role for IRSA first ###

# The cluster is already looked up in init.tf as `data.aws_eks_cluster.eks_cluster_data`. Data sources are layer-global, so reference it directly here (e.g. for the OIDC issuer): data.aws_eks_cluster.eks_cluster_data.identity[0].oidc[0].issuer

module "external_secrets_irsa" {
  source = "../modules/iam-module/iam-role-for-service-account"
  create = var.create_external_secrets_operator
  region = var.region
  description = "IAM role for External Secrets Operator"
  name = "${var.project_name}-${var.env}-external-secrets-operator-role"

  oidc_providers = {
    eks = {
      provider_arn = data.aws_eks_cluster.eks_cluster_data.identity[0].oidc[0].issuer
      namespace_service_accounts = ["${var.k8s_namespaces[1]}:external-secrets-operator"]
    }
  }

}

