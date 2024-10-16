output "post_integration_id" {
  value = aws_api_gateway_integration.lambda_integration.id
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.api_deployment.stage_name}"
}