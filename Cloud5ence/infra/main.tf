terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment after creating the state bucket manually:
  # backend "s3" {
  #   bucket = "cloud5ence-tfstate"
  #   key    = "website/terraform.tfstate"
  #   region = "ca-central-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ACM must be in us-east-1 for CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ── S3 BUCKET ──────────────────────────────────────────────
resource "aws_s3_bucket" "site" {
  bucket = var.domain_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

# ── ACM CERTIFICATE ─────────────────────────────────────────
resource "aws_acm_certificate" "site" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = var.tags
  lifecycle { create_before_destroy = true }
}

# ── CLOUDFRONT OAC ──────────────────────────────────────────
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.domain_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CLOUDFRONT DISTRIBUTION ─────────────────────────────────
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "cloud5ence.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  comment             = "cloud5ence.com"
  tags                = var.tags

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "S3-${var.domain_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.domain_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # SPA routing — 404 serves index
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/cloud5ence.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ── S3 BUCKET POLICY (CloudFront OAC only) ──────────────────
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
        }
      }
    }]
  })
}

# ── OUTPUTS ─────────────────────────────────────────────────
output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.site.id
  description = "Add to GitHub secret: CLOUDFRONT_DISTRIBUTION_ID"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.site.id
  description = "Add to GitHub secret: S3_BUCKET_NAME"
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.site.domain_name
}

output "website_url" {
  value = "https://${var.domain_name}"
}
