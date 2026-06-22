resource "cloudflare_zero_trust_access_group" "tomioka_jcom_ip" {
  account_id = var.cloudflare_account_id
  name       = "tomioka_Jcom_IP"
  include = [{
    ip = {
      ip = "119.175.137.121/32"
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "tomioka_en_hikari_ip" {
  account_id = var.cloudflare_account_id
  name       = "tomioka_enHikari_IP"
  include = [{
    ip = {
      ip = "119.105.108.223/32"
    }
    }, {
    ip = {
      ip = "106.73.185.193/32"
    }
    }, {
    # フレッツ光クロス IPv6 PD(OpenWrt WAN6)
    ip = {
      ip = "240b:11:b9d0:7600::/56"
    }
  }]
}

resource "cloudflare_zero_trust_access_group" "tomioka_home" {
  account_id = var.cloudflare_account_id
  name       = "TomiokaHome"
  include = [{
    group = {
      id = cloudflare_zero_trust_access_group.tomioka_jcom_ip.id
    }
    }, {
    group = {
      id = cloudflare_zero_trust_access_group.tomioka_en_hikari_ip.id
    }
  }]
}
