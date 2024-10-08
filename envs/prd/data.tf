data "aws_route53_zone" "prod" {
  name = local.zone_name
}