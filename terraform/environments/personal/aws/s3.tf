# s3.tf
resource "aws_s3_bucket" "website" {
  bucket = "disk0401.net"

  tags = {
    Name = "MyWebSite"
  }
}

resource "aws_s3_bucket" "cloudfront_access_log" {
  bucket = "cf-accesslog-disk0401.net"

  tags = {
    Name = "MyWebSite"
  }
}

resource "aws_s3_bucket" "cost_usage_report" {
  bucket = "disk0401-cost-usage-report"
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket = "disk0401-ct"

  tags = {
    Name = "CloudTrail"
  }
}