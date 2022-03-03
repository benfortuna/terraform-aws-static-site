data "aws_caller_identity" "current" {}

resource "aws_route53_zone" "zone" {
  count = var.domain != null ? 1 : 0
  name  = var.domain
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket" "logs" {
  bucket = var.logs_bucket != null ? var.logs_bucket : format("%s-access-logs", data.aws_caller_identity.current.account_id)
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = var.cloudfront_enabled
  price_class         = var.price_class
  default_root_object = var.default_root_object

  custom_error_response {
    error_code         = 404
    response_page_path = var.error_page
    response_code      = 404
  }

  aliases = var.aliases

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_domain_name
    origin_id   = "S3-${aws_s3_bucket.bucket.bucket}"
  }

  default_cache_behavior {
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      cookies {
        forward = "none"
      }

      query_string = false
    }

    target_origin_id = "S3-${aws_s3_bucket.bucket.bucket}"
    default_ttl      = var.default_ttl
    max_ttl          = var.max_ttl
  }

  ordered_cache_behavior {
    path_pattern           = "*+*"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      cookies {
        forward = "none"
      }

      query_string = false
    }

    target_origin_id = "S3-${aws_s3_bucket.bucket.bucket}"
    default_ttl      = var.default_ttl
    max_ttl          = var.max_ttl

#    lambda_function_association {
#      event_type   = "viewer-request"
#      lambda_arn   = "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:CloudFrontRewrite:1"
#      include_body = false
#    }
  }

  logging_config {
    bucket = aws_s3_bucket.logs.bucket_domain_name
    prefix = "cloudfront-${aws_s3_bucket.bucket.bucket}/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_record" "www" {
  count   = var.domain != null ? length(var.aliases) : 0
  zone_id = aws_route53_zone.zone[0].zone_id
  name    = element(var.aliases, count.index)
  type    = "CNAME"

  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.distribution.id
    zone_id                = aws_route53_zone.zone[0].zone_id
  }
}
