output "zone_id" {
  description = "The Route53 hosted zone ID (use this for ACM validation + CloudFront alias records)"
  value       = module.route53.id
}

output "zone_arn" {
  description = "The Route53 hosted zone ARN"
  value       = module.route53.arn
}

output "zone_name" {
  description = "The Route53 hosted zone name"
  value       = module.route53.name
}

output "name_servers" {
  description = "The zone's name servers (set these as Custom DNS nameservers in Namecheap)"
  value       = module.route53.name_servers
}
