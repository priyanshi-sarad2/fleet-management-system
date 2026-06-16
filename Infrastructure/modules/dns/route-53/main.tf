########     Route 53 DNS Module     ########

module "route53" {
  source  = "terraform-aws-modules/route53/aws"
  version = "6.5.0"

  # Master toggle + create (vs lookup) a brand-new public hosted zone
  create      = var.create_route53_zone
  create_zone = var.create_route53_zone

  # The domain this hosted zone is for (e.g. "priyanshiseniordevops.online")
  name    = var.zone_name
  comment = var.zone_comment

  # Allow the zone to be destroyed even if it still has records (handy for teardown)
  force_destroy = var.zone_force_destroy

  tags    = var.zone_tags
  records = var.zone_records
}
