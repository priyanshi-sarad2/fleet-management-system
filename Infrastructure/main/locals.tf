########    Locals     ########

locals {
  # Root/apex domain for the Route53 hosted zone and ACM certificate.
  # Kept independent of the CloudFront origins map (the zone/cert should exist
  # even when there are no CloudFront distributions).
  root_domain = var.root_domain
}