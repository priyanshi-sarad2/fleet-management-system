project_name = "fleetman"
region       = "us-east-1"
env          = "prod"
account_id = "176777036446"


create_external_secrets_operator = true

k8s_namespaces = ["fleetman-prod", "external-secrets-operator"]


# Helm charts to install (keyed by release name). Empty map installs nothing.
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
  }
}