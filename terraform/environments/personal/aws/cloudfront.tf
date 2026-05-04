# terraform/environments/personal/aws/cloudfront.tf

resource "aws_cloudfront_distribution" "disk0401_net" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  http_version        = "http2"
  comment             = ""

  aliases = ["disk0401.net"]

  origin {
    origin_id   = "S3-disk0401.net"
    domain_name = "disk0401.net.s3.amazonaws.com"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${var.cf_oai_id}"
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3-disk0401.net"
    viewer_protocol_policy = "redirect-to-https"
    compress               = false

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/error/404.html"
    error_caching_min_ttl = 10
  }

  logging_config {
    bucket          = "cf-accesslog-disk0401.net.s3.amazonaws.com"
    include_cookies = false
    prefix          = ""
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:${var.aws_account_id}:certificate/${var.acm_certificate_id}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {}
}