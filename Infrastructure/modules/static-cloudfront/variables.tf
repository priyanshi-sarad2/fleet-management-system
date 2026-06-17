########   Global / tagging   ########
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
variable "project_name" {
  description = "Project name (used to build the CloudFront origin id)"
  type        = string
  default     = ""
}

########   Origin Access Control   ########
variable "cloudfront_oac_name" {
  description = "Name for the CloudFront Origin Access Control"
  type        = string
}
variable "cloudfront_oac_description" {
  description = "Description for the CloudFront Origin Access Control"
  type        = string
  default     = null
}

########   Origin / distribution   ########
variable "s3_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (CloudFront origin)"
  type        = string
}
variable "cloudfront_comment" {
  description = "Comment shown on the CloudFront distribution"
  type        = string
  default     = null
}
variable "cloudfront_root_object" {
  description = "Root object to serve for the CloudFront distribution"
  type        = string
  default     = null
}
variable "static_cloudfront_aliases" {
  description = "List of domain names (aliases) for the CloudFront distribution"
  type        = list(string)
  default     = []
}
variable "cloudfront_price_class" {
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100"
  type        = string
  default     = null
}

########   Cache TTLs   ########
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

########   TLS   ########
variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate (must be in us-east-1 for CloudFront)"
  type        = string
}

########   Cache behaviour   ########
variable "allowed_methods" {
  description = "List of HTTP methods allowed for the CloudFront distribution."
  type        = list(string)
}
variable "cached_methods" {
  description = "List of HTTP methods that should be cached."
  type        = list(string)
}
variable "cookies_forward" {
  description = "How CloudFront forwards cookies to the origin (none/whitelist/all)"
  type        = string
}

########   SPA error page fallback   ########
variable "enable_error_page" {
  description = "Flag to enable or disable custom error pages (SPA fallback)"
  type        = bool
  default     = false
}
variable "error_response_page" {
  description = "Page to serve for the custom error response (e.g. /index.html)"
  type        = string
  default     = null
}
variable "error_code" {
  description = "Error code to remap to the error_response_page (e.g. 403)"
  type        = number
  default     = null
}
