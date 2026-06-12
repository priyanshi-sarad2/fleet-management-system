########     S3 Bucket Module     ########

module "s3-bucket" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "5.9.1"
  create_bucket            = var.create_bucket
  bucket                   = var.bucket_name
  force_destroy            = true # Allow deletion of bucket even if it contains objects
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  acl                      = "private"

  versioning = {
    enabled = var.bucket_versioning
  }

  # Apply lifecycle_rule only when versioning is enabled
  lifecycle_rule = var.bucket_versioning ? var.lifecycle_rule : []



  block_public_acls       = var.enable_block_public_access ? true : false
  block_public_policy     = var.enable_block_public_access ? true : false
  ignore_public_acls      = var.enable_block_public_access ? true : false
  restrict_public_buckets = var.enable_block_public_access ? true : false

  tags = {
    Terraform = "True"
    Project   = var.name
    Service   = var.app
  }

  cors_rule = var.add_cors ? var.cors_rule : []

  website = var.enable_website ? {
    index_document = var.index_page
    error_document = var.error_page
  } : {}

}