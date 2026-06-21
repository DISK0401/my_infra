# アカウント全体のGateway設定(DNS/HTTPフィルタリング等)
resource "cloudflare_zero_trust_gateway_settings" "account" {
  account_id = var.cloudflare_account_id
  settings = {
    activity_log = null
    antivirus    = null
    block_page   = null
    fips         = null
    tls_decrypt = {
      enabled = false
    }
  }
}
