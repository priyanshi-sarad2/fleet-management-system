variable "create_s3_bucket_policy" {
  description = "Create s3 bucket policy"
  type        = bool
  default     = false
}
variable "s3_static_bucket_id" {
  description = "The name (ID) of the static S3 bucket"
  type        = string
}
variable "s3_static_bucket_arn" {
  description = "The name (ID) of the static S3 bucket"
  type        = string
}
variable "s3_folder_name" {
  type    = string
  default = null
}
variable "static_cloudfront_arn" {
  description = "The name (ID) of the static S3 bucket"
  type        = string
}
variable "allow_put_object" {
  type    = bool
  default = false
}
variable "make_bucket_folder_public" {
  type    = bool
  default = false
}