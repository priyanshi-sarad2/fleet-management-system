###   Helm   ###

# One Helm release per entry in var.helm_charts (keyed by release name).
# Empty map -> nothing is installed.

module "helm_charts" {
  source   = "../modules/helm"
  for_each = var.helm_charts

  helm_release_name  = each.key
  helm_repository    = each.value.repository
  helm_chart_name    = each.value.chart_name
  helm_chart_version = each.value.chart_version
  helm_namespace     = each.value.namespace
  helm_set           = each.value.set
}
