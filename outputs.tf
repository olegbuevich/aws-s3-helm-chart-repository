output "s3_bucket_name" {
  description = "The name of S3 bucket for HELM charts"
  value       = aws_s3_bucket.this.bucket
}

output "cloudfront_distribution_id" {
  description = "The CloudFront distribution ID"
  value       = aws_cloudfront_distribution.this.id
}
