import {
  to = aws_cloudfront_origin_access_identity.disk0401_net
  id = var.cf_oai_id
}

import {
  to = aws_s3_bucket_policy.website
  id = "disk0401.net"
}
