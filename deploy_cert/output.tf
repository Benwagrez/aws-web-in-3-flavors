output "acm_cert_arn" {
    value = aws_acm_certificate.cert.arn
}

output "acm_east_cert_arn" {
    value = aws_acm_certificate.cert_east.arn
}