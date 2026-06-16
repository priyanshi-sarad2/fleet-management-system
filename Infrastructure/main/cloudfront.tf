module "cloudfront-distribution-webapp" {
  for_each = var.web_apps
  source = "../modules/cloudfront"
  project_name = var.project_name
  cloudfront_comment = "${var.project_name} ${each.key} cloudfront distribution"
  cloudfront_aliases = [each.value.domain]
  acm_certificate_arn = each.value.acm_certificate_arn
  origin_dns_name = each.value.alb_origin_domain
  cloudfront_origin_protocol_policy = "https-only"

  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400

  enable_backend_response_headers = true
  response_headers_policy_name    = "${var.project_name}-${each.key}-response-headers-policy"
}