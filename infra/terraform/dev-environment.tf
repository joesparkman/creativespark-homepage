# ─────────────────────────────────────────────────────────────
# dev.joesparkman.com - isolated staging mirror of the production
# site. Safe to destroy/rebuild independently: separate bucket,
# separate CloudFront distribution, no shared state with prod other
# than reusing the existing wildcard ACM cert (*.joesparkman.com
# already covers this subdomain, so no new cert/validation needed)
# and the quickbite-spa-routing function (identical routing rules).
# ─────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "dev" {
  bucket = "dev.joesparkman.com"
}

resource "aws_s3_bucket_website_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket = aws_s3_bucket.dev.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dev" {
  bucket = aws_s3_bucket.dev.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dev.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.dev]
}

data "aws_cloudfront_cache_policy" "dev_caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "dev" {
  provider = aws.us_east_1

  aliases             = ["dev.joesparkman.com"]
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  price_class         = "PriceClass_100"
  comment             = "Staging mirror of joesparkman.com - safe to destroy/rebuild independently of prod"

  origin {
    origin_id   = "dev-origin"
    domain_name = aws_s3_bucket_website_configuration.dev.website_endpoint

    custom_origin_config {
      http_port                = 80
      https_port                = 443
      origin_protocol_policy    = "http-only"
      origin_ssl_protocols      = ["TLSv1.2"]
      origin_read_timeout       = 30
      origin_keepalive_timeout  = 5
    }
  }

  default_cache_behavior {
    target_origin_id       = "dev-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = data.aws_cloudfront_cache_policy.dev_caching_optimized.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.quickbite_spa_routing.arn
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
