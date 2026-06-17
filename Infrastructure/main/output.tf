# output "eks_oidc_provider_arn" {
#   description = "OIDC provider ARN used for IRSA (null if EKS not created or IRSA disabled)"
#   value       = try(module.eks.oidc_provider_arn, null)
# }

# output "eks_cluster_oidc_issuer_url" {
#   description = "OIDC issuer URL used for IRSA (null if EKS not created)"
#   value       = try(module.eks.cluster_oidc_issuer_url, null)
# }


# # Output the Route53 zone name servers
# output "route53_zone_name_servers" {
#   value = module.route53.name_servers
# }