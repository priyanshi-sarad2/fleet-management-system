####   Kubernetes External Secrets Operator    ####

### Creating service account first for External Secrets Operator ###
# The namespace is already created for it
# This service account is annotated with the IRSA role ARN so that the External Secrets Operator can read secrets from Secrets Manager.

module "external_secrets_service_account" {
  source = "../modules/k8s-modules/k8s-namespace/service-account"
  count  = var.create_external_secrets_operator ? 1 : 0

  service_account_name = "external-secrets-operator"
  namespace            = var.k8s_namespaces[1]

  # IRSA: link this service account to the IAM role so ESO can read Secrets Manager
  annotations = {
    "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.arn
  }
}



### Creating IAM role for IRSA first ###

module "external_secrets_irsa" {
  source = "../modules/iam-module/iam-role-for-service-account"
  create = var.create_external_secrets_operator

  region      = var.region
  description = "IAM role for External Secrets Operator"
  name        = "${var.project_name}-${var.env}-external-secrets-operator-role"

  oidc_providers = {
    eks = {
      provider_arn               = data.aws_iam_openid_connect_provider.eks_oidc_provider.arn
      namespace_service_accounts = ["${var.k8s_namespaces[1]}:${var.k8s_namespaces[1]}"]
    }
  }

  attach_external_secrets_policy = true
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:${var.project_name}-${var.env}/*"
  ]
  # This will add both the secrets in the list to the role
}

### ClusterSecretStore (custom resource) ###
# Created after ESO is installed via Helm (the CRD must exist first).
# Cluster-scoped, so it has NO namespace. It tells ESO where to read secrets from
# (AWS Secrets Manager) and how to authenticate (IRSA via the ESO service account).

module "eso_cluster_secret_store" {
  source = "../modules/k8s-modules/kubectl-manifest"
  count  = var.create_external_secrets_operator ? 1 : 0

  api_version = "external-secrets.io/v1"
  kind        = "ClusterSecretStore"
  name        = "aws-secretsmanager"
  # cluster-scoped -> no namespace

  spec = {
    provider = {
      aws = {
        service = "SecretsManager"
        region  = var.region
        auth = {
          jwt = {
            serviceAccountRef = {
              name      = "external-secrets-operator"
              namespace = var.k8s_namespaces[1]
            }
          }
        }
      }
    }
  }

  # ESO Helm release installs the CRD first. With kubectl_manifest this depends_on
  # actually works in a single apply (no CRD needed at plan time).
  depends_on = [module.helm_charts]
}
