output "post_integration_id" {
  value = aws_api_gateway_integration.lambda_integration.id
}

output "api_endpoint" {
  value = aws_api_gateway_deployment.api_deployment.rest_api_id
}