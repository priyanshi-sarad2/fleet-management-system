#### Cloudfront for apps with alb origin ####

# The API gateway's ALB is created by the AWS Load Balancer Controller (Helm, in the
# addons layer) from the Ingress, so it isn't a Terraform resource here. We look it up
# by the tags the controller applies (group.name = "fleetman" -> ingress.k8s.aws/stack).
# NOTE: requires the addons/Ingress to already exist, so apply this after the ALB is up.
data "aws_lb" "api_alb" {
  count = length(var.cloudfront_alb_origins) > 0 ? 1 : 0
  tags = {
    "ingress.k8s.aws/stack" = "fleetman"
    "elbv2.k8s.aws/cluster" = "${var.project_name}-eks-cluster"
  }
}

# CloudFront distribution per API entry (custom ALB origin, caching disabled).
module "cloudfront_api" {
  for_each = var.cloudfront_alb_origins
  source   = "../modules/cloudfront"

  project_name       = var.project_name
  cloudfront_comment = "${var.project_name} ${each.key} API cloudfront distribution"
  cloudfront_aliases = [each.value.domain]

  # Origin = the controller-created ALB (looked up via the data source above).
  origin_dns_name                   = one(data.aws_lb.api_alb[*].dns_name)
  origin_path                       = each.value.origin_path
  cloudfront_origin_protocol_policy = each.value.origin_protocol_policy

  # API responses must not be cached.
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0

  # Same wildcard cert as the static distributions (covers *.<root_domain>),
  # or the tfvars override if provided.
  acm_certificate_arn = var.acm_certificate_arn != null ? var.acm_certificate_arn : one(module.acm[*].acm_certificate_arn)
}




########    Static webapp hosting   ########

# 1) S3 bucket per webapp
module "webapp_s3" {
  for_each = var.cloudfront_s3_origins
  source   = "../modules/s3"

  name        = "${var.project_name}-${var.env}"
  app         = each.key
  bucket_name = "${each.key}-${var.env}"
}

# 2) CloudFront distribution per app
module "cloudfront_static" {
  for_each = var.cloudfront_s3_origins
  source   = "../modules/static-cloudfront"

  name         = var.project_name
  app          = each.key
  env          = var.env
  project_name = var.project_name

  cloudfront_oac_name        = "${each.key}-${var.env}-oac"
  cloudfront_oac_description = "OAC for ${each.key} (${var.env})"
  cloudfront_comment         = "${var.project_name} ${each.key} cloudfront distribution"

  s3_regional_domain_name   = module.webapp_s3[each.key].s3_regional_domain_name
  static_cloudfront_aliases = [each.value.domain]
  cloudfront_root_object    = each.value.root_object
  cloudfront_price_class    = each.value.price_class

  # Use the ACM ARN from tfvars if provided; otherwise fall back to the
  # wildcard cert created in acm.tf (covers *.<root_domain>).
  acm_certificate_arn = var.acm_certificate_arn != null ? var.acm_certificate_arn : one(module.acm[*].acm_certificate_arn)

  allowed_methods = each.value.allowed_methods
  cached_methods  = each.value.cached_methods
  cookies_forward = each.value.cookies_forward

  # SPA fallback: a private S3 bucket returns 403 for unknown paths -> serve index.html
  enable_error_page   = each.value.enable_error_page
  error_code          = each.value.error_code
  error_response_page = "/${each.value.root_object}"
}



# 3) Bucket policy: allow ONLY this CloudFront distribution (OAC) to read the bucket
module "webapp_s3_policy" {
  for_each = var.cloudfront_s3_origins
  source   = "../modules/s3-bucket-policy"

  create_s3_bucket_policy = true
  s3_static_bucket_id     = module.webapp_s3[each.key].s3_bucket_id
  s3_static_bucket_arn    = module.webapp_s3[each.key].s3_bucket_arn
  static_cloudfront_arn   = module.cloudfront_static[each.key].cloudfront_distribution_arn
}