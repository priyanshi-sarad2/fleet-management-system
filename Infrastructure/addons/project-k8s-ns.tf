resource "kubernetes_namespace" "project_k8s_namespace" {
  metadata {
    annotations = {
      name = "${var.project_name}-${var.env}"
    }

    labels = {
      project = var.project_name
      env     = var.env
    }

    name = "${var.project_name}-${var.env}"
  }
}