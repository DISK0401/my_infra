resource "cloudflare_zero_trust_tunnel_cloudflared" "openwrt" {
  account_id = var.cloudflare_account_id
  config_src = "cloudflare"
  name       = "OpenWrt"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "pve03_windows_server_2022" {
  account_id = var.cloudflare_account_id
  config_src = "cloudflare"
  name       = "pve03-WindowsServer2022"
}
