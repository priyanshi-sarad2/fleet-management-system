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

variable "enable_block_public_access" {
  type    = bool
  default = true
}
variable "lifecycle_rule" {
  description = "Lifecycle rules for the bucket"
  type        = any
  default     = []
}

########   Bucket Specific   ########
variable "create_bucket" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = true
}
variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
  default     = null
}
variable "bucket_versioning" {
  description = "Enable versioning for s3 static bucket"
  type        = bool
  default     = false
}

# Needed for static website hosting - If you have to enable the website hosting
variable "enable_website" {
  type    = bool
  default = false
}
variable "index_page" {
  description = "Index page that has to be served"
  type        = string
  default     = "index.html"
}
variable "error_page" {
  description = "Error page that has to be served"
  type        = string
  default     = "error.html"
}

variable "add_cors" {
  description = "Enable or disable CORS configuration on the S3 bucket"
  type        = bool
  default     = false
}
variable "cors_rule" {
  description = "List of CORS rules to apply to the S3 bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}
