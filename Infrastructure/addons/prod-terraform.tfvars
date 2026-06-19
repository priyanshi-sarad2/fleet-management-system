project_name = "fleetman"
region       = "us-east-1"
env          = "prod"
account_id = "176777036446"


create_external_secrets_operator = true

# k8s_namespaces = []

k8s_namespaces = ["fleetman-prod", "external-secrets-operator", "load-balancer-controller"]

# Helm charts to install (keyed by release name). Empty map installs nothing.
# helm_charts = {}

helm_charts = {
  "external-secrets" = {
    repository    = "https://charts.external-secrets.io"
    chart_name    = "external-secrets"
    chart_version = "0.20.4"
    namespace     = "external-secrets-operator"
    set = [
      { name = "installCRDs", value = "true" },
      # use the pre-created IRSA service account instead of letting the chart make one
      { name = "serviceAccount.create", value = "false" },
      { name = "serviceAccount.name", value = "external-secrets-operator" },
    ]
  },
  "load-balancer-controller" = {
    repository    = "https://aws.github.io/eks-charts"
    chart_name    = "aws-load-balancer-controller"
    chart_version = "1.14.0"
    namespace     = "load-balancer-controller"

    # CRDs are installed automatically on first install by Helm chart 1.14.0.
    # If you ever upgrade this release, apply CRDs manually before/after upgrade.
    set = [
      { name = "clusterName", value = "fleetman-eks-cluster" },
      { name = "region", value = "us-east-1" },
      { name = "serviceAccount.create", value = "false" },
      { name = "serviceAccount.name", value = "load-balancer-controller" },
    ]
  }
}