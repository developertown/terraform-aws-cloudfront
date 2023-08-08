output "domain_name" {
  value = one(aws_cloudfront_distribution.cloudfront_distribution[*].domain_name)
}
