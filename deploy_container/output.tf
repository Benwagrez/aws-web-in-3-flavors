output "app_gw_dns" {
    value = aws_lb.alb.dns_name
}

output "app_gw_zone_id" {
    value = aws_lb.alb.zone_id
}