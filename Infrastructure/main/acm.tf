########    ACM     ########

module "acm" {
  source = "../modules/acm"
  count  = var.create_acm_certificate ? 1 : 0

  # count above already gates creation; this makes the module actually issue the cert.
  create_public_certificate = true

  # CloudFront requires the certificate in us-east-1.
  region = "us-east-1"

  project_name                  = var.project_name
  domain_name                   = local.root_domain
  certificate_alternative_names = ["*.${local.root_domain}"]
  zone_id                       = module.route53.zone_id
}