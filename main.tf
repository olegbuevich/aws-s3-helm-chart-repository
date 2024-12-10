locals {
  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# S3
################################################################################

locals {
  bucket = var.bucket_name != "" ? var.bucket_name : "helm-repo-${uuidv5("dns", "${local.aws_account_id}-${local.aws_region}")}"
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "allow_access_from_cloudfront" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_cloudfront_distribution.this.arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_access_from_cloudfront.json
}

# ################################################################################
# # CloudFront
# ################################################################################

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "this" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_origin_request_policy" "this" {
  name    = local.bucket
  comment = "Managed by Terraform (S3 helm repository)"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "none"
  }
}

locals {
  s3_origin_id = local.bucket

  cloudfront_origin_access_control_name       = local.bucket
  cloudfront_origin_access_control_descrition = "Managed by Terraform (S3 helm repository)"
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.create_cloudfront_origin_access_control ? 1 : 0

  name                              = local.cloudfront_origin_access_control_name
  description                       = local.cloudfront_origin_access_control_descrition
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  comment = "helm repositories"

  enabled         = true
  is_ipv6_enabled = true

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = try(aws_cloudfront_origin_access_control.this[0].id, var.cloudfront_origin_access_control_id)
    origin_id                = local.s3_origin_id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    cache_policy_id            = data.aws_cloudfront_cache_policy.this.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.this.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.this.id

    viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
