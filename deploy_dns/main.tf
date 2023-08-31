
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

resource "aws_route53_record" "root-a" {
  count = var.deployS3 ? 1 : 0

  zone_id = data.aws_route53_zone.benwagrez-public-zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.root_s3_distribution_domain_name
    zone_id                = var.root_s3_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www-a" {
  count = var.deployS3 ? 1 : 0

  zone_id = data.aws_route53_zone.benwagrez-public-zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.www_s3_distribution_domain_name
    zone_id                = var.www_s3_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cname_route53_record" {
  count = var.deployvm ? 1 : 0

  zone_id = data.aws_route53_zone.benwagrez-public-zone.zone_id # Replace with your zone ID
  name    = var.domain_name # Replace with your subdomain, Note: not valid with "apex" domains, e.g. example.com
  type    = "A"

  alias {
    name                   = var.record
    zone_id                = var.record_zone
    evaluate_target_health = true
  }
}