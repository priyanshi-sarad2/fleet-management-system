###  Kubernetes manifest (via the kubectl provider)  ###
#
# Uses `kubectl_manifest` (server-side apply of raw YAML) instead of `kubernetes_manifest`.
# Key benefit: the resource's CRD does NOT need to exist at PLAN time, so this is safe for
# Custom Resources whose CRD is installed by a Helm release in the SAME apply
# (combine with depends_on for correct ordering).

terraform {
  required_providers {
    kubectl = {
      source = "alekc/kubectl"
    }
  }
}

resource "kubectl_manifest" "this" {
  yaml_body = yamlencode(merge(
    {
      "apiVersion" = var.api_version
      "kind"       = var.kind
      # namespace is omitted for cluster-scoped resources (e.g. ClusterSecretStore)
      "metadata" = merge(
        { "name" = var.name },
        var.namespace != null ? { "namespace" = var.namespace } : {}
      )
    },
    var.spec != null ? { "spec" = var.spec } : {}
  ))
}
