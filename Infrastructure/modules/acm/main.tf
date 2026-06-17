##  ACM Module - public certificate, DNS-validated via Route 53     ##

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  create_certificate = var.create_public_certificate

  # CloudFront certs MUST be in us-east-1; pass the right region from the caller.
  region                    = var.region
  domain_name               = var.domain_name
  subject_alternative_names = var.certificate_alternative_names

  # DNS validation, with the validation records created automatically in our
  # own Route 53 hosted zone (no manual CNAME copying needed).
  validation_method      = "DNS"
  create_route53_records = true
  zone_id                = var.zone_id

  # Wait until ACM has validated the cert before the apply completes.
  wait_for_validation = true

  tags = {
    Terraform = "True"
    Project   = var.project_name
    Service   = "acm"
  }
}
