####     Kubernetes Namespaces    ####
# One namespace is created per entry in var.k8s_namespaces.
# If the list is empty, for_each iterates over nothing -> no namespaces are created.

module "k8s_namespace" {
  source   = "../modules/k8s-modules/k8s-namespace"
  for_each = toset(var.k8s_namespaces)

  namespace    = each.value
  project_name = var.project_name
  env          = var.env
}
