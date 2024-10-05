provider "aws" {
  region = "us-east-1"
}

# S3 Bucket for Static Website
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

# DynamoDB Table
resource "aws_dynamodb_table" "fruit_orders" {
  name         = "fruit_orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "order_id"

  attribute {
    name = "order_id"
    type = "S"
  }
}

# IAM Role for Lambda
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

# Lambda Function
resource "aws_lambda_function" "process_order" {
  function_name = "process_order"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename = "process_order.zip" # Prepackaged Lambda code
  role     = aws_iam_role.lambda_exec_role.arn
  timeout  = 10

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.fruit_orders.name
    }
  }
}

# API Gateway for Lambda
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
