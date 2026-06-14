output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider (used by IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading https://)"
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enable_irsa = true"
  value       = module.eks.oidc_provider_arn
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

