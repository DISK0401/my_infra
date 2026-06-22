# アカウント全体のGateway設定(DNS/HTTPフィルタリング等)
resource "cloudflare_zero_trust_gateway_settings" "account" {
  account_id = var.cloudflare_account_id
  settings = {
    activity_log = {
      enabled = true
    }
    antivirus  = null
    block_page = null
    fips       = null
    tls_decrypt = {
      enabled = false
    }
  }
}

# DNSレイヤーでマルウェア・フィッシング等の既知の脅威カテゴリ(Security threats)をブロックする
resource "cloudflare_zero_trust_gateway_policy" "block_security_threats" {
  account_id  = var.cloudflare_account_id
  name        = "block-security-threats"
  description = "既知のマルウェア・フィッシング・ボットネット等のドメインをDNSレイヤーでブロックする"
  action      = "block"
  enabled     = true
  filters     = ["dns"]
  precedence  = 1000
  traffic     = "any(dns.content_category[*] in {21})"
}
