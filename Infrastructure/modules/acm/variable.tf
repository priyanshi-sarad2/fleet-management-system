variable "create_public_certificate" {
  description = "Whether to create the public ACM certificate"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region to create the certificate in (use us-east-1 for CloudFront)"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Primary domain name the certificate is issued for"
  type        = string
  default     = ""
}

variable "certificate_alternative_names" {
  description = "Additional SAN domains for the certificate (e.g. subdomains or a wildcard)"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route53 hosted zone ID where the DNS validation records are created"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name, used for tagging"
  type        = string
  default     = ""
}
