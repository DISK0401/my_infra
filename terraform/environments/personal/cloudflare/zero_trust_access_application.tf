resource "cloudflare_zero_trust_access_application" "rdp" {
  account_id                 = var.cloudflare_account_id
  app_launcher_visible       = true
  auto_redirect_to_identity  = false
  domain                     = "rdp.disk0401.com"
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  name                       = "rdp"
  options_preflight_bypass   = false
  session_duration           = "24h"
  skip_interstitial          = true
  type                       = "rdp"
  destinations = [{
    type = "public"
    uri  = "rdp.disk0401.com"
  }]
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.admin.id
      precedence = 1
    },
    {
      id         = cloudflare_zero_trust_access_policy.tomioka_home.id
      precedence = 2
    },
  ]
  target_criteria = [{
    port     = 3389
    protocol = "RDP"
    target_attributes = {
      hostname = ["WinServer2022"]
    }
  }]
}

resource "cloudflare_zero_trust_access_application" "home" {
  account_id                 = var.cloudflare_account_id
  app_launcher_visible       = true
  auto_redirect_to_identity  = false
  domain                     = "openwrt.disk0401.com"
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  name                       = "home"
  options_preflight_bypass   = false
  session_duration           = "24h"
  type                       = "self_hosted"
  destinations = [{
    type = "public"
    uri  = "openwrt.disk0401.com"
    }, {
    type = "public"
    uri  = "grafana.disk0401.com"
    }, {
    type = "public"
    uri  = "influxdb.disk0401.com"
    }, {
    type = "public"
    uri  = "synology.disk0401.com"
  }]
  policies = [
    {
      id         = cloudflare_zero_trust_access_policy.admin.id
      precedence = 1
    },
    {
      id         = cloudflare_zero_trust_access_policy.tomioka_home.id
      precedence = 2
    },
  ]
}
