###   Kubernetes Manifests   ###

resource "kubernetes_manifest" "k8s-manifests" {
  manifest = {
    "apiVersion" = var.k8s_manifests_api_version
    "kind"       = var.k8s_manifests_kind
    "metadata" = merge(
      { "name" = var.k8s_manifests_name },
      var.k8s_manifests_namespace != null ? { "namespace" = var.k8s_manifests_namespace } : {}
    )
    "spec" = var.k8s_manifests_spec
  }
}

# The namespace key is included ONLY when a namespace is provided. If var.k8s_manifests_namespace is null, the key is omitted entirely (required for cluster-scoped resources like ClusterSecretStore).