locals {
  cloudfront_origin_id = "s3-${var.project_name}-${var.env}"
}
/*
  Here we are defining a local variable
  cloudfront_origin_id is just a label or internal reference used only inside your CloudFront distribution configuration
  It helps CloudFront link cache behaviors to a specific origin (like your S3 bucket)
  Since there can be multiple origins in cloudfront distribution - this origin-id helps to uniquely identify
  a single origin.
*/

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "cloudfront-distribution-OAC" {
  name        = var.cloudfront_oac_name
  description = var.cloudfront_oac_description

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# Cache policy for the static site (modern replacement for the deprecated
# `forwarded_values` block). Everything about the cache key is driven from the
# per-origin tfvars values, so it stays controllable in one place:
#   - query strings : var.query_string   (false => "none")
#   - headers        : var.headers        ([]    => "none")
#   - cookies        : var.cookies_forward ("none")
# TTLs come from var.min/default/max_ttl. gzip + brotli are enabled so the edge
# can serve compressed text assets (HTML/JS/CSS).
resource "aws_cloudfront_cache_policy" "static" {
  name    = "${var.name}-${var.env}-${var.app}-static-cache"
  comment = "Cache policy for ${var.app} (${var.env}) static site"

  min_ttl     = var.min_ttl
  default_ttl = var.default_ttl
  max_ttl     = var.max_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    query_strings_config {
      query_string_behavior = var.query_string ? "all" : "none"
    }

    headers_config {
      header_behavior = length(var.headers) > 0 ? "whitelist" : "none"

      dynamic "headers" {
        for_each = length(var.headers) > 0 ? [1] : []
        content {
          items = var.headers
        }
      }
    }

    cookies_config {
      cookie_behavior = var.cookies_forward
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront-distribution" {

  origin {
    domain_name              = var.s3_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront-distribution-OAC.id
    origin_id                = local.cloudfront_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.cloudfront_comment
  default_root_object = var.cloudfront_root_object
  aliases             = var.static_cloudfront_aliases


  default_cache_behavior {
    allowed_methods  = var.allowed_methods
    cached_methods   = var.cached_methods
    target_origin_id = local.cloudfront_origin_id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Modern cache policy (replaces the deprecated forwarded_values + inline
    # TTLs, which are mutually exclusive with cache_policy_id). For a static SPA
    # the policy keeps the cache key to just the URL path (query strings /
    # headers / cookies all "none" via tfvars) to maximise the cache hit ratio.
    cache_policy_id = aws_cloudfront_cache_policy.static.id
  }


  price_class = var.cloudfront_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Terraform = "True"
    Project   = var.name
    Service   = var.app
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # This is done because of an Issue in cloudfront - when root domain can successfully access the site (index.html)
  # But when there is any endpoint added at the end of root domain - it gives access denied 403
  # like this -> domain.com/sign-in
  dynamic "custom_error_response" {
    for_each = var.enable_error_page ? [1] : []
    content {
      error_code            = var.error_code
      response_code         = 200
      response_page_path    = var.error_response_page
      error_caching_min_ttl = 300
    }
  }
}