locals {
  env           = "prd"
  domain_prefix = "jaz-cloudfront"
  zone_name     = "sctp-sandbox.com"
}

module "static_web_stack" {
  source = "../../modules/cloudfront-s3"

  env                 = local.env
  acm_certificate_arn = module.acm.acm_certificate_arn
  aliases             = ["${local.domain_prefix}-${local.env}.${local.zone_name}"]
  web_acl_id          = module.waf.web_acl_arn
}

module "waf" {
  source = "../../modules/waf"

  providers = {
    aws = aws.us-east-1
  }

  env = local.env
}

module "acm" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.us-east-1
  }

  domain_name       = "${local.domain_prefix}-${local.env}.${local.zone_name}"
  zone_id           = data.aws_route53_zone.prod.zone_id
  validation_method = "DNS"
}

module "records" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = local.zone_name

  records = [
    {
      name = "${local.domain_prefix}-${local.env}"
      type = "A"
      alias = {
        name    = "${module.static_web_stack.cloudfront_domain}"
        zone_id = "Z2FDTNDATAQYW2"
      }
    },
  ]
}