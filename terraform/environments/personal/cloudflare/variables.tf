#################################################
# Cloudflare固有変数
#################################################

variable "cloudflare_account_id" {
  description = "CloudflareアカウントID"
  type        = string
}

variable "cloudflare_google_idp_client_secret" {
  description = "Google Identity Provider OAuth Client Secret"
  type        = string
  sensitive   = true
}
