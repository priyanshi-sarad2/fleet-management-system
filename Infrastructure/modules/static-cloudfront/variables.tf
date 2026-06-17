########   Global   ########
variable "name" {
  description = "Project Name -> Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}
variable "app" {
  description = "Project app"
  type        = string
  default     = null
}
variable "env" {
  type    = string
  default = null
}
variable "website_name" {
  type = string
}




variable "s3_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  type        = string
}
variable "cloudfront_root_object" {
  type        = string
  description = "Root object to serve for CloudFront distribution"
  default     = null
}
variable "static_cloudfront_aliases" {
  description = "List of domain names (aliases) for the CloudFront distribution"
  type        = list(string)
  default     = []
}
variable "static_cloudfront_price_class" {
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100"
  type        = string
  default     = null
}

variable "min_ttl" {
  description = "Minimum TTL (seconds) for objects in the CloudFront cache"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL (seconds) for objects in the CloudFront cache"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL (seconds) for objects in the CloudFront cache"
  type        = number
  default     = 86400
}
variable "acm_certificate_arn" { # Will be same for all cloudfront
  description = "ARN of the public certificate you created from AWS Certificate Manager"
  type        = string
}
variable "allowed_methods" {
  description = "List of HTTP methods allowed for the CloudFront distribution or S3 bucket."
  type        = list(string)
}
variable "cached_methods" {
  description = "List of HTTP methods that should be cached."
  type        = list(string)
}
variable "cookies_forward" {
  type = string
}
variable "public_key" {
  type    = string
  default = null
}
variable "key_group" {
  type    = string
  default = null
}
variable "enable_cloudfront_key" {
  type    = bool
  default = false
}
variable "enable_error_page" {
  description = "Flag to enable or disable custom error pages"
  type        = bool
  default     = false
}
variable "error_response_page" {
  type    = string
  default = null
}
variable "error_code" {
  type    = number
  default = null
}

variable "enable_frontend_response_headers" {
  type    = bool
  default = false
}
variable "response_headers_policy_name" {
  type    = string
  default = null
}
variable "frontend_csp_whitelist" {
  type    = string
  default = null
}
variable "frontend_referrer_policy" {
  type    = string
  default = null
}