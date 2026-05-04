import {
  to = aws_cloudfront_distribution.disk0401_net
  id = var.cf_distribution_id
}

import {
  to = aws_acm_certificate.disk0401_net
  id = "arn:aws:acm:us-east-1:${var.aws_account_id}:certificate/${var.acm_certificate_id}"
}