####     Kubernetes Namespace    ####


resource "kubernetes_namespace_v1" "project_k8s_namespace" {
  count = var.create_project_k8s_namespace ? 1 : 0
  metadata {
    annotations = {
      name = "${var.project_name}-${var.env}"
    }

    labels = {
      project = var.project_name
      env     = var.env
      Terraform = "True"
    }

    name = "${var.project_name}-${var.env}"

  }

  lifecycle {
    prevent_destroy = true
  }
}