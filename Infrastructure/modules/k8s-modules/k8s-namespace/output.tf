output "namespace" {
  description = "The name of the created namespace"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}
