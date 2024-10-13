# data "aws_route53_zone" "prod" {
#   name = local.zone_name
# }

#===========================================
# data - Lambda Function for processing orders
#===========================================
data "archive_file" "dynamodb_lambda_function" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "${path.module}/process_order.zip"
}

#===================================================
# data-IAM Policy Document for S3 CloudFront Access
#===================================================
data "aws_iam_policy_document" "default" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

