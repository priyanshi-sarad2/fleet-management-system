project_name = "fleetman"
region       = "us-east-1"
env          = "prod"


create_external_secrets_operator = true
create_load_balancer_controller  = true
create_aws_cloudwatch_fluent_bit = true

# k8s_namespaces = []

k8s_namespaces = ["fleetman-prod", "external-secrets-operator", "load-balancer-controller", "amazon-cloudwatch"]

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
      # NOTE: vpcId is injected dynamically in helm.tf (from the EKS cluster data source),
      # because the nodes' IMDS hop limit blocks pods from auto-discovering the VPC.
      # Disable the Service mutating webhook (only needed for NLB-via-Service).
      # We use ALB via Ingress, and this prevents the controller from intercepting/
      # blocking Service creation cluster-wide if its pods are ever unavailable.
      { name = "enableServiceMutatorWebhook", value = "false" },
      { name = "serviceAccount.create", value = "false" },
      { name = "serviceAccount.name", value = "load-balancer-controller" },
    ]

    # This chart needs the VPC ID -> helm.tf appends it dynamically from the cluster.
    inject_vpc_id = true
  },
  "aws-cloudwatch-fluent-bit" = {
    repository    = "https://aws.github.io/eks-charts"
    chart_name    = "aws-for-fluent-bit"
    chart_version = "0.2.0"
    namespace     = "amazon-cloudwatch"

    set = [
      # Use the pre-created IRSA service account (made in aws-cloudwatch-fluent-bit.tf),
      # not one created by the chart, so the CloudWatch IAM role is attached.
      { name = "serviceAccount.create", value = "false" },
      { name = "serviceAccount.name", value = "aws-cloudwatch-fluent-bit" },

      # Only collect logs from pods in the fleetman-prod namespace (the 3 apps).
      # Container log filenames are <pod>_<namespace>_<container>-<id>.log, so the
      # middle segment matches the namespace. This skips kube-system/addons noise.
      { name = "input.path", value = "/var/log/containers/*_fleetman-prod_*.log" },

      # Ship pod logs to CloudWatch Logs using the high-performance plugin.
      { name = "cloudWatchLogs.enabled", value = "true" },
      { name = "cloudWatchLogs.region", value = "us-east-1" },
      { name = "cloudWatchLogs.autoCreateGroup", value = "true" },
      { name = "cloudWatchLogs.logRetentionDays", value = "7" },

      # Per-app log groups like /aws/eks/fleetman/<app>; logGroupName is the required
      # fallback used when a pod has no `app` label (e.g. system pods).
      { name = "cloudWatchLogs.logGroupName", value = "/aws/eks/fleetman/applications" },
      { name = "cloudWatchLogs.logGroupTemplate", value = "/aws/eks/fleetman/$kubernetes['labels']['app']" },
      { name = "cloudWatchLogs.logStreamPrefix", value = "fleetman-" },

      # Send only the application message (the `log` field), not the whole JSON
      # envelope. App/pod identity is already captured by the log group + stream.
      { name = "cloudWatchLogs.logKey", value = "log" },
    ]

    # Fluent Bit does not need the VPC ID.
    inject_vpc_id = false
  }
}

# ALB Controller CRDs note:
# Helm install installs CRDs automatically, but helm upgrade does not update them.
# If you upgrade and need to refresh CRDs manually, run:
# wget https://raw.githubusercontent.com/aws/eks-charts/master/stable/aws-load-balancer-controller/crds/crds.yaml
# kubectl apply -f crds.yaml
