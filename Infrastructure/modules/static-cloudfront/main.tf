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
  name                              = var.cloudfront_oac_name
  description                       = var.cloudfront_oac_description

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
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

    forwarded_values {
      query_string = true

      cookies {
        forward = var.cookies_forward
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = true

    response_headers_policy_id = var.enable_frontend_response_headers ? aws_cloudfront_response_headers_policy.frontend_response_headers_policy[0].id : null
  }


  price_class = var.static_cloudfront_price_class

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



########    CloudFront Response Headers Policy     ########
resource "aws_cloudfront_response_headers_policy" "frontend_response_headers_policy" {
  count = var.enable_frontend_response_headers ? 1 : 0
  name  = var.response_headers_policy_name

  security_headers_config {
    content_security_policy {
      override                = true // cloudfront will override any CSP policy received from origin from its own
      content_security_policy = var.frontend_csp_whitelist
    }

    strict_transport_security {
      override                   = true
      access_control_max_age_sec = 31536000 // 1 year in seconds
      include_subdomains         = true
      preload                    = true
    }

    referrer_policy {
      override        = true
      referrer_policy = var.frontend_referrer_policy
    }

    xss_protection {
      mode_block = true
      override   = true
      protection = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      override     = true
      frame_option = "SAMEORIGIN"
    }
  }
  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      override = true
      value    = "geolocation=(self); camera=(); microphone=();"
    }
  }
}