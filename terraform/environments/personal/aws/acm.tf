resource "aws_acm_certificate" "disk0401_net" {
  provider          = aws.us_east_1
  domain_name       = "disk0401.net"
  validation_method = "DNS"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "MyWebSite"
  }
}
