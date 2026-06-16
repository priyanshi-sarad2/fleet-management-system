output "name" {
  description = "Name of the applied manifest"
  value       = kubectl_manifest.this.name
}
