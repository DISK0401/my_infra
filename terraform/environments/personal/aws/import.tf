import {
  to = aws_cloudtrail.main
  id = "arn:aws:cloudtrail:ap-northeast-1:${var.aws_account_id}:trail/CloudTrail"
}

import {
  to = aws_s3_bucket_policy.cloudtrail
  id = "disk0401-ct"
}
