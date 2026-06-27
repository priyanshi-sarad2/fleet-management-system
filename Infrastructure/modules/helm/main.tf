###   Helm   ###

resource "helm_release" "helm" {
  name       = var.helm_release_name
  repository = var.helm_repository
  chart      = var.helm_chart_name
  version    = var.helm_chart_version
  namespace  = var.helm_namespace
  # The set block is how you override the chart's values — it's the Terraform equivalent of helm install ... --set service.type=ClusterIP.
  set = var.helm_set
}