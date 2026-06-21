resource "cloudflare_zero_trust_access_policy" "admin" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "admin"
  session_duration = "24h"
  include = [{
    email = {
      email = "mail@disk0401.net"
    }
  }]
}

resource "cloudflare_zero_trust_access_policy" "tomioka_home" {
  account_id       = var.cloudflare_account_id
  decision         = "allow"
  name             = "tomioka_home"
  session_duration = "24h"
  include = [{
    group = {
      id = cloudflare_zero_trust_access_group.tomioka_en_hikari_ip.id
    }
    }, {
    group = {
      id = cloudflare_zero_trust_access_group.tomioka_jcom_ip.id
    }
  }]
}
