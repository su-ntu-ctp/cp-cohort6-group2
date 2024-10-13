provider "aws" {
  region = "us-east-1"
}
#=============================================
# S3 Bucket for Static Website
#=============================================
resource "aws_s3_bucket" "static_site" {
  bucket = "my-fruit-shop-static-site"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  timeouts {
    create = "15m"
  }
}
#=========================================
# DynamoDB Table
#=========================================
resource "aws_dynamodb_table" "fruit_orders" {
  name         = "fruit_orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}
#========================================
# IAM Role for Lambda
#========================================

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

EOF
}
#=========================================
#Additional policy for Lambda Full access
#=========================================
resource "aws_iam_role_policy_attachment" "lambda_full_access_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}
#=========================================
#Additional policy for DynamoDB
#=========================================
resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

#=========================================
#Additional policy for Lambda S3
#=========================================
resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}
#=======================================
# IAM Policy for Lambda to access SES
#========================================
resource "aws_iam_policy" "lambda_ses_policy" {
  name = "lambda_ses_policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ses:SendEmail",
            "Resource": "*"
        }
    ]
}
EOF
}

# Attach SES policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_exec_role_ses" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_ses_policy.arn
}

# Lambda Function to send email notifications
resource "aws_lambda_function" "send_email" {
  function_name = "send_email_notification"
  handler       = "email_lambda.lambda_handler"
  runtime       = "python3.8"

  filename = "send_email.zip" # Prepackaged Lambda code for sending email
  role     = aws_iam_role.lambda_exec_role.arn
  timeout  = 10

  environment {
    variables = {
      EMAIL_SENDER    = "xin_wang_xin@hotmail.com" # Replace with a verified SES email
      EMAIL_RECIPIENT = "xin_wang_xin@hotmail.com"            # The email recipient
    }
  }
}

#========================================
# Lambda Function for processing orders
#========================================
data "archive_file" "dynamodb_lambda_function" {
  type = "zip"
  source_file = "lambda_function.py"
  output_path = "${path.module}/process_order.zip"
}

resource "aws_lambda_function" "process_order" {
  function_name = "process_order"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename = "process_order.zip" # Prepackaged Lambda code
  role     = aws_iam_role.lambda_exec_role.arn
  timeout  = 10

  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.fruit_orders.name
      EMAIL_LAMBDA_ARN = aws_lambda_function.send_email.arn # Add the email Lambda ARN
    }
  }
}
#=========================================
# API Gateway for Lambda
#=========================================
resource "aws_api_gateway_rest_api" "api" {
  name        = "FruitShopAPI"
  description = "API for processing fruit shop orders"
}

resource "aws_api_gateway_resource" "orders_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "orders_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.orders_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.orders_resource.id
  http_method             = aws_api_gateway_method.orders_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.process_order.invoke_arn
}

# Integration Response for POST
resource "aws_api_gateway_integration_response" "post_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.orders_resource.id
  http_method = aws_api_gateway_method.orders_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "*"
    "method.response.header.Access-Control-Allow-Methods" = "*"
  }
}

# Method Response for POST
resource "aws_api_gateway_method_response" "post_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.orders_resource.id
  http_method = aws_api_gateway_method.orders_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

#=====================================================
# S3 Bucket Policy to Allow CloudFront Access
#=====================================================
resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.static_site.id

  policy = data.aws_iam_policy_document.default.json
}

#=====================================================
# CloudFront Distribution
#=====================================================
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "origin-${aws_s3_bucket.static_site.id}"
  }

  aliases             = var.aliases
  web_acl_id          = var.web_acl_id
  enabled             = true
  comment             = "Static Website using S3 and Cloudfront OAC in ${var.env} environment"
  default_root_object = "index.html"

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "origin-${aws_s3_bucket.static_site.id}"
    viewer_protocol_policy = "allow-all"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }
}

#==================================================
# CloudFront Origin Access Control
#==================================================
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${aws_s3_bucket.static_site.id}-oac-${var.env}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# IAM Policy Document for S3 CloudFront Access
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




# new set of code from line 170 onwards
# provider "aws" {
#   region = "us-east-1"
# }

# # S3 Bucket for Static Website
# resource "aws_s3_bucket" "static_site" {
#   bucket = "my-fruit-shop-static-site"

#   timeouts {
#     create = "15m"
#   }
# }

# # S3 Bucket ACL for Public Read Access
# resource "aws_s3_bucket_acl" "static_site_acl" {
#   bucket = aws_s3_bucket.static_site.id
#   acl    = "public-read"  # Allow public access to the website
# }

# # S3 Bucket Website Configuration
# resource "aws_s3_bucket_website_configuration" "static_site_website" {
#   bucket = aws_s3_bucket.static_site.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "error.html"
#   }
# }

# # DynamoDB Table
# resource "aws_dynamodb_table" "fruit_orders" {
#   name         = "fruit_orders"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "order_id"

#   attribute {
#     name = "order_id"
#     type = "S"
#   }
# }


# # Lambda Function
# resource "aws_lambda_function" "process_order" {
#   function_name = "process_order"
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.8"

#   filename = "process_order.zip" # Prepackaged Lambda code
#   role     = aws_iam_role.lambda_exec_role.arn
#   timeout  = 10

#   environment {
#     variables = {
#       DYNAMODB_TABLE = aws_dynamodb_table.fruit_orders.name
#     }
#   }
# }

# # API Gateway for Lambda
# resource "aws_api_gateway_rest_api" "api" {
#   name        = "FruitShopAPI"
#   description = "API for processing fruit shop orders"
# }

# resource "aws_api_gateway_resource" "orders_resource" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   parent_id   = aws_api_gateway_rest_api.api.root_resource_id
#   path_part   = "orders"
# }

# resource "aws_api_gateway_method" "orders_post" {
#   rest_api_id   = aws_api_gateway_rest_api.api.id
#   resource_id   = aws_api_gateway_resource.orders_resource.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.api.id
#   resource_id             = aws_api_gateway_resource.orders_resource.id
#   http_method             = aws_api_gateway_method.orders_post.http_method
#   type                    = "AWS_PROXY"
#   integration_http_method = "POST"
#   uri                     = aws_lambda_function.process_order.invoke_arn
# }

# resource "aws_api_gateway_deployment" "api_deployment" {
#   depends_on  = [aws_api_gateway_integration.lambda_integration]
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   stage_name  = "prod"
# }

# resource "aws_lambda_permission" "api_gateway_permission" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.process_order.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
# }

# # CloudFront Origin Access Identity
# resource "aws_cloudfront_origin_access_identity" "s3_access_identity" {
#   comment = "Origin Access Identity for S3"
# }

# # CloudFront Distribution
# resource "aws_cloudfront_distribution" "static_site_distribution" {
#   origin {
#     domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name
#     origin_id   = "S3Origin"

#     s3_origin_config {
#       origin_access_identity = aws_cloudfront_origin_access_identity.s3_access_identity.id
#     }
#   }

#   enabled             = true
#   default_root_object = "index.html"

#   default_cache_behavior {
#     target_origin_id       = "S3Origin"
#     viewer_protocol_policy = "redirect-to-https"

#     allowed_methods = [
#       "GET",
#       "HEAD",
#     ]

#     cached_methods = ["GET", "HEAD"]

#     forwarded_values {
#       query_string = false

#       cookies {
#         forward = "none"  # No cookies are forwarded
#       }
#     }

#     compress = true  # Enable compression
#   }

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#     cloudfront_default_certificate = true
#   }

#   comment = "CloudFront distribution for my fruit shop static site"
# }
