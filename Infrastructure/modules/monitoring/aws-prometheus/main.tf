# AWS Managed Prometheus

module "managed-service-prometheus" {
  source  = "terraform-aws-modules/managed-service-prometheus/aws"
  version = "4.3.1"

  create           = var.create
  region           = var.region
  create_workspace = var.create_workspace
  workspace_alias  = var.workspace_alias

  ####  Workspace Settings  ####
  retention_period_in_days = var.retention_period_in_days

  ####  Resource Policy  ####
  # For a same-account EKS -> AMP -> Grafana setup, leaving
  # resource_policy_statements = null uses the upstream defaults:
  # - this AWS account can remote write and query
  # - Amazon Managed Grafana can query the workspace
  create_resource_policy     = var.create_resource_policy
  resource_policy_statements = var.resource_policy_statements


  ####  Cloudwatch Log Group  ####
  cloudwatch_log_group_name              = var.cloudwatch_log_group_name
  cloudwatch_log_group_use_name_prefix   = false
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days


  ####  Alert Manager  ####
  create_alert_manager = var.create_alert_manager

  tags = var.tags
}