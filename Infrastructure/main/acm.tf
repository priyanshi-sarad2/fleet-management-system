########    ACM     ########

module "acm" {
  source = "../modules/acm"
  count  = var.create_acm_certificate ? 1 : 0

  project_name               = var.project_name
  create_public_certificate  = true

  # ACM Certificate should always be in us-east-1 for CloudFront (cloudfront is a global service)
  region = "us-east-1"

  domain_name                   = local.root_domain
  certificate_alternative_names = ["*.${local.root_domain}"]
  zone_id                       = module.route53.zone_id
}