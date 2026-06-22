resource "cloudflare_zero_trust_tunnel_cloudflared_config" "openwrt" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openwrt.id
  config = {
    warp_routing = {
      enabled = true
    }
    ingress = [
      {
        hostname = "openwrt.disk0401.com"
        service  = "http://192.168.1.1"
        origin_request = {
          access = {
            aud_tag   = []
            team_name = "disk0401"
            required  = false
          }
        }
      },
      {
        hostname       = "grafana.disk0401.com"
        service        = "http://grafana:3000"
        origin_request = {}
      },
      {
        hostname       = "influxdb.disk0401.com"
        service        = "http://192.168.1.10:8086"
        origin_request = {}
      },
      {
        hostname = "synology.disk0401.com"
        service  = "https://synology:5001"
        origin_request = {
          no_tls_verify = true
        }
      },
      {
        service = "http_status:503"
        origin_request = {
          connect_timeout        = 0
          keep_alive_connections = 0
          keep_alive_timeout     = 0
          tcp_keep_alive         = 0
          tls_timeout            = 0
        }
      },
    ]
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "pve03_windows_server_2022" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.pve03_windows_server_2022.id
  config = {
    warp_routing = {
      enabled = true
    }
    ingress = [
      {
        service = "http_status:404"
      },
    ]
  }
}

# WARP Private Network経由でのアクセス対象(疑似VPN/RDP用の内部ルート)
resource "cloudflare_zero_trust_tunnel_cloudflared_route" "home_network" {
  account_id = var.cloudflare_account_id
  network    = "192.168.1.0/24"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.openwrt.id
  comment    = "自宅ネットワーク"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "winserver2022" {
  account_id = var.cloudflare_account_id
  network    = "192.168.1.18/32"
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.pve03_windows_server_2022.id
  comment    = "WinServer2022"
}
