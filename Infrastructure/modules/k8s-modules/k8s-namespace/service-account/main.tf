###   Kubernetes Service Account   ###

resource "kubernetes_service_account_v1" "service_account" {
  count = var.create ? 1 : 0
  metadata {
    name        = var.service_account_name
    namespace   = var.namespace
    annotations = var.annotations
    labels      = var.labels
  }
}