#===========================================
# data - Lambda Function for processing orders
#===========================================
data "archive_file" "dynamodb_lambda_function" {
  type        = "zip"
  source_file = "../../lambda_function.py"
  output_path = "${path.module}/process_order.zip"
}

#===================================================
# data-IAM Policy Document for S3 CloudFront Access
#===================================================
data "aws_iam_policy_document" "default" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.cloudfront-s3.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront-s3.s3_distribution_arn]
    }
  }
}

