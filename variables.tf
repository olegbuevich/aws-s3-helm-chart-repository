variable "bucket_name" {
  description = "The name of S3 bucket for helm charts"
  type        = string
  default     = ""
}

variable "create_cloudfront_origin_access_control" {
  description = "Whether to create AWS CloudFront Origin Access Control"
  type        = bool
  default     = true
}

variable "cloudfront_origin_access_control_id" {
  description = "The ID of AWS CloudFront Origin Access Control"
  type        = string
  default     = ""
}
