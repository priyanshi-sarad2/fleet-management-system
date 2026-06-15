###   Kubernetes Service Account   ###

resource "kubernetes_service_account" "service_account" {
  metadata {
    name = var.service_account_name
    namespace = var.namespace
    annotations = var.annotations
    labels = var.labels
  }
}