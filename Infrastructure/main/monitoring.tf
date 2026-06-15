######## Monitoring ########

module "irsa-eks-prometheus-writer-iam-role" {
  source = "../modules/iam-module/iam-role-for-service-account"

  create      = var.setup_eks_cluster_monitoring
  region      = var.region
  name        = "${var.project_name}-eks-prometheus-adot-writer-role"
  description = "IRSA role for EKS Prometheus writer"

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["adot-col:amp-iamproxy-ingest-service-account"]
    }
  }

  attach_amazon_managed_service_prometheus_policy = true
  amazon_managed_service_prometheus_workspace_arns = [
    module.aws-managed-prometheus.workspace_arn
  ]
  /*
    This trust policy is for the ADOT collector that scrapes metrics in EKS and remote_writes them to Amazon Managed Prometheus.

    It trusts the cluster OIDC provider and only allows this Kubernetes
    identity to assume the role:
    - namespace: adot-col
    - service account: amp-iamproxy-ingest-service-account
  */


}


module "aws-managed-prometheus" {
  source = "../modules/monitoring/aws-prometheus"

  create           = var.setup_eks_cluster_monitoring
  region           = var.region
  create_workspace = true
  workspace_alias  = "${var.project_name}-aws-prometheus"

  #### Workspace Settings ####
  retention_period_in_days = var.prometheus_retention_period_in_days

  #### Resource Policy ####
  # The workspace policy allows the ADOT IRSA role to remote_write into AMP
  # and allows Amazon Managed Grafana to query the workspace.
  create_resource_policy = var.setup_eks_cluster_monitoring
  resource_policy_statements = {
    eks_remote_write = {
      sid     = "AllowEksPrometheusWriter"
      actions = ["aps:RemoteWrite"]
      principals = [
        {
          type        = "AWS"
          identifiers = [module.irsa-eks-prometheus-writer-iam-role.arn]
        }
      ]
    }

    grafana_read = {
      sid = "AllowGrafanaRead"
      actions = [
        "aps:QueryMetrics",
        "aps:GetSeries",
        "aps:GetLabels",
        "aps:GetMetricMetadata"
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["grafana.amazonaws.com"]
        }
      ]
    }
  }


  ####  Cloudwatch Log Group  ####
  cloudwatch_log_group_name              = "${var.project_name}-eks-prometheus-adot-writer-log-group"
  cloudwatch_log_group_retention_in_days = var.prometheus_cloudwatch_log_group_retention_in_days



  ####  Alert Manager  ####
  create_alert_manager = false

  tags = {
    Project     = var.project_name
    Environment = var.env
    Terraform   = "true"
    Service     = "monitoring"
  }
}




module "aws-managed-grafana" {
  source = "../modules/monitoring/aws-grafana"

  create_grafana  = var.setup_eks_cluster_monitoring
  grafana_version = var.grafana_version

  ### Workspace Settings ###
  workspace_name        = "${var.project_name}-aws-grafana"
  workspace_description = "AWS Managed Grafana workspace for ${var.project_name}"

  account_access_type = var.grafana_account_access_type

  permission_type = var.grafana_permission_type

  authentication_providers = var.grafana_authentication_providers

  data_sources = var.grafana_data_sources

  role_associations = var.grafana_role_associations

  network_access_control = var.grafana_network_access_control

  associate_license = var.associate_license



  tags = {
    Project   = var.project_name
    Terraform = "true"
  }
}