#################################################
# 共通変数（他環境でも使用する可能性があるもの）
#################################################

variable "home_server_ip" {
  description = "自宅サーバのIPアドレス"
  type        = string
}

#################################################
# AWS固有変数
#################################################
variable "aws_account_id" {
  description = "AWSアカウントID"
  type        = string
}

variable "cf_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
}

variable "cf_oai_id" {
  description = "CloudFront Origin Access Identity ID"
  type        = string
}

variable "acm_certificate_id" {
  description = "ACM Certificate ID"
  type        = string
}
