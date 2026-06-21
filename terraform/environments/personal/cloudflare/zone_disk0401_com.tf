resource "cloudflare_zone" "disk0401_com" {
  name   = "disk0401.com"
  paused = false
  type   = "full"

  account = {
    id = var.cloudflare_account_id
  }
}

resource "cloudflare_dns_record" "disk0401_com_rdp_a" {
  zone_id  = cloudflare_zone.disk0401_com.id
  name     = "rdp.disk0401.com"
  type     = "A"
  content  = "240.0.0.0"
  ttl      = 1
  proxied  = true
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "disk0401_com_rdp_aaaa" {
  zone_id  = cloudflare_zone.disk0401_com.id
  name     = "rdp.disk0401.com"
  type     = "AAAA"
  content  = "100::"
  ttl      = 1
  proxied  = true
  tags     = []
  settings = {}
}

resource "cloudflare_dns_record" "disk0401_com_grafana_cname" {
  zone_id = cloudflare_zone.disk0401_com.id
  name    = "grafana.disk0401.com"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwrt.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "disk0401_com_influxdb_cname" {
  zone_id = cloudflare_zone.disk0401_com.id
  name    = "influxdb.disk0401.com"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwrt.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "disk0401_com_openwrt_cname" {
  zone_id = cloudflare_zone.disk0401_com.id
  name    = "openwrt.disk0401.com"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwrt.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "disk0401_com_synology_cname" {
  zone_id = cloudflare_zone.disk0401_com.id
  name    = "synology.disk0401.com"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwrt.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  tags    = []
  settings = {
    flatten_cname = false
  }
}

resource "cloudflare_dns_record" "disk0401_com_winserver_cname" {
  zone_id = cloudflare_zone.disk0401_com.id
  name    = "winserver.disk0401.com"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.openwrt.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
  tags    = []
  settings = {
    flatten_cname = false
  }
}
