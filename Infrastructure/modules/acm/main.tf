##  ACM Module - for public certificates     ##

module "acm" {
  source             = "terraform-aws-modules/acm/aws"
  version            = "6.3.0"
  create_certificate = var.create_public_certificate


  region             = var.region
  domain_name        = var.domain_name
  subject_alternative_names = var.certificate_alternative_names

  wait_for_validation = true
  validation_method = "DNS"

  create_route53_records  = false

  tags = {
    Name = "weekly.tf"
  }
}