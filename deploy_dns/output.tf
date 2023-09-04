output "hosted_zone_id" {
    value = data.aws_route53_zone.benwagrez-public-zone.id
}

output "DNS_record" {
    value = aws_route53_record.alias_alb_route53_record != [] ? aws_route53_record.alias_alb_route53_record[0].fqdn : null
}