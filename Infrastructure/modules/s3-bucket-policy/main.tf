########     S3 Bucket Policy Module     ########

resource "aws_s3_bucket_policy" "s3-cloudfront-access" {
  count  = var.create_s3_bucket_policy ? 1 : 0
  bucket = var.s3_static_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "AllowCloudFrontServicePrincipalReadOnly"
          Effect = "Allow"
          Principal = {
            Service = "cloudfront.amazonaws.com"
          }
          Action   = var.allow_put_object ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"]
          Resource = "${var.s3_static_bucket_arn}/*"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = var.static_cloudfront_arn
            }
          }
        }
      ],
      var.make_bucket_folder_public ? [
        {
          Sid       = "AllowPublicAccessToUploads"
          Effect    = "Allow"
          Principal = "*"
          Action    = "s3:GetObject"
          Resource  = "arn:aws:s3:::${var.s3_static_bucket_id}/${var.s3_folder_name}/*"
        }
      ] : []
    )
  })
}


# resource "aws_s3_bucket_policy" "s3-cloudfront-access" {
#   count  = var.create_s3_bucket_policy ? 1 : 0
#   bucket = var.s3_static_bucket_id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AllowCloudFrontServicePrincipalReadOnly"
#         Effect    = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = var.allow_put_object ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"]
#         Resource = "${var.s3_static_bucket_arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = var.static_cloudfront_arn
#           }
#         }
#       }
#     ]
#   })
# }
