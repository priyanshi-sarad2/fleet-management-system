########     Route 53 DNS Module     ########

module "route53" {
  source  = "terraform-aws-modules/route53/aws"
  version = "6.5.0"

  # Master toggle + create (vs lookup) a brand-new public hosted zone
  create      = var.create_route53_zone
  create_zone = var.create_route53_zone

  # The domain this hosted zone is for
  name    = var.domain_name
  comment = var.zone_comment

  # Allow the zone to be destroyed even if it still has records (handy for teardown)
  force_destroy = var.zone_force_destroy

  tags = {
    Terraform = "True"
    Project   = var.project_name
    Service   = "route53"
  }
  records = var.zone_records
}
