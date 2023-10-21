# Certificate Outputs are shown below
output "acm_alb_cert_arn" {
    value = aws_acm_certificate.alb_cert.arn
}

output "acm_east_cert_arn" {
    value = aws_acm_certificate.cert_east.arn
}