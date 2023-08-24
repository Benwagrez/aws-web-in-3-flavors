
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

data "aws_route53_zone" "benwagrez-public-zone" {
  zone_id = var.zone_id
}

resource "aws_route53_record" "website-record" {
  zone_id = data.aws_route53_zone.benwagrez-public-zone.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = var.record
}