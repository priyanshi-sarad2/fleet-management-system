########     Route 53 - public hosted zone for the domain     ########

locals {
  # The first web app's domain from the web_apps map,
  webapp_domain = try(values(var.web_apps)[0].domain, null)

  # Strip the leftmost label to get the apex/root domain for the hosted zone,
  apex_domain = local.webapp_domain == null ? null : join(".", slice(
    split(".", local.webapp_domain),
    1,
    length(split(".", local.webapp_domain))
  ))
}

module "route53" {
  source              = "../modules/dns/route-53"
  create_route53_zone = var.create_route53_zone
  domain_name         = local.apex_domain
  project_name        = var.project_name
  zone_comment        = "${var.project_name} ${var.env} public hosted zone"
  zone_force_destroy  = true
  zone_records        = var.zone_records
}
