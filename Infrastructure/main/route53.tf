########     Route 53 - public hosted zone for the domain     ########
module "route53" {
  source              = "../modules/dns/route-53"
  create_route53_zone = var.create_route53_zone
  domain_name         = var.domain_name
  project_name        = var.project_name
  zone_comment        = "${var.project_name} ${var.env} public hosted zone"
  zone_force_destroy  = true
}
