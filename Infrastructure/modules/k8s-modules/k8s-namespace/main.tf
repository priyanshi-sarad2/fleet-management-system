####     Kubernetes Namespace    ####
# Creates a single namespace. Iteration (and the "empty list -> create nothing"
# behaviour) is handled by the caller via for_each.

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace

    labels = {
      project   = var.project_name
      env       = var.env
      Terraform = "True"
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}
