output "root_cloudfront_domain_name" {
    value = aws_cloudfront_distribution.root_s3_distribution.domain_name
}

output "root_cloudfront_hosted_zone_id" {
    value = aws_cloudfront_distribution.root_s3_distribution.hosted_zone_id
}

output "www_cloudfront_domain_name" {
    value = aws_cloudfront_distribution.www_s3_distribution.domain_name
}

output "www_cloudfront_hosted_zone_id" {
    value = aws_cloudfront_distribution.www_s3_distribution.hosted_zone_id
}