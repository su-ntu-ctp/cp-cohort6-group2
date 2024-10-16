locals {
  env           = "dev"
  domain_prefix = "myfruitshop"
  zone_name     = "sctp-sandbox.com"
}


module "cloudfront-s3" {
  #source = "../modules/cloudfront-s3"
  source = "../../modules/Cloudfront-S3"
  env    = local.env
}


module "lambda-db-api" {
  #source = "../modules/ambda-db-api"
  source = "../../modules/Lambda-DB-API"
  env    = local.env
}