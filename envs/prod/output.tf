output "cf_domain" {
  value = module.cloudfront-s3.cloudfront_domain
}

output "cf_id" {
  value = module.cloudfront-s3.cloudfront_id
}

output "bucket_name" {
  value = module.cloudfront-s3.bucket_name
}

output "api_endpoint" {
  value = module.lambda-db-api.api_endpoint
}
