########    ACM     ########

module "acm" {
  source = "../modules/acm"
  project_name = var.project_name
  domain_name = local.root_domain
  certificate_alternative_names = ["*.${local.root_domain}"]
  zone_id = module.route53.zone_id
}