resource "aws_eks_addon" "this" {
  count = var.create ? 1 : 0

  region                      = var.region
  cluster_name                = var.cluster_name
  addon_name                  = var.addon_name
  addon_version               = var.addon_version
  configuration_values        = var.configuration_values
  service_account_role_arn    = var.service_account_role_arn
  preserve                    = var.preserve
  resolve_conflicts_on_create = var.resolve_conflicts_on_create
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
}