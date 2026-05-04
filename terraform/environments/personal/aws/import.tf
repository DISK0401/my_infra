import {
  to = aws_s3_bucket.website
  id = "disk0401.net"
}

import {
  to = aws_s3_bucket.cloudfront_access_log
  id = "cf-accesslog-disk0401.net"
}

import {
  to = aws_s3_bucket.cost_usage_report
  id = "disk0401-cost-usage-report"
}

import {
  to = aws_s3_bucket.cloudtrail
  id = "disk0401-ct"
}