variable "create_route53_zone" {
  description = "Whether to create the Route53 public hosted zone"
  type        = bool
  default     = false
}

variable "zone_name" {
  description = "The domain name for the hosted zone (e.g. example.com)"
  type        = string
  default     = ""
}

variable "zone_comment" {
  description = "A comment for the hosted zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "zone_force_destroy" {
  description = "Destroy all records in the zone when destroying the zone"
  type        = bool
  default     = false
}

variable "zone_tags" {
  description = "Tags to apply to the hosted zone"
  type        = map(string)
  default     = {}
}

variable "zone_records" {
  description = "Map of DNS records to create in the zone (see terraform-aws-modules/route53 records schema)"
  type        = any
  default     = {}
}
