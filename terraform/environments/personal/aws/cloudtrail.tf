resource "aws_cloudtrail" "main" {
  name                          = "CloudTrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = false

  tags = {
    Name = "CloudTrail"
  }
}
