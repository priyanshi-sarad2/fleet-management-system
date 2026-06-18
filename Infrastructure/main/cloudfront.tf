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

  # Cert is the wildcard cert created in acm.tf (covers *.<root_domain>)
  acm_certificate_arn = one(module.acm[*].acm_certificate_arn)

  allowed_methods = ["GET", "HEAD", "OPTIONS"]
  cached_methods  = ["GET", "HEAD"]
  cookies_forward = "none"

  # SPA fallback: a private S3 bucket returns 403 for unknown paths -> serve index.html
  enable_error_page   = true
  error_code          = 403
  error_response_page = "/index.html"
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
