# HE.net IPv6 Certification "Sage" 取得のための一時構成。
# Sageはドメイン配下(in-bailiwick)のネームサーバーにTLDでIPv6 glueがあることを要求するため、
# 既存Route53ネームサーバーと同一IPを指す white-label NS (ns1-4.disk0401.net) をglue付きで委任する。
# 合格後は委任先を元の awsdns-* に戻す。NSの委任TTLが172800秒のため、
# ns1-4のA/AAAAレコードは戻してから2日以上経ってから削除すること。

locals {
  disk0401_net_white_label_ns = {
    ns1 = { ipv4 = "205.251.193.225", ipv6 = "2600:9000:5301:e100::1" } # ns-481.awsdns-60.com
    ns2 = { ipv4 = "205.251.195.20", ipv6 = "2600:9000:5303:1400::1" }  # ns-788.awsdns-34.net
    ns3 = { ipv4 = "205.251.196.17", ipv6 = "2600:9000:5304:1100::1" }  # ns-1041.awsdns-02.org
    ns4 = { ipv4 = "205.251.198.219", ipv6 = "2600:9000:5306:db00::1" } # ns-1755.awsdns-27.co.uk
  }
}

resource "aws_route53_record" "disk0401_net_white_label_ns_a" {
  for_each = local.disk0401_net_white_label_ns

  zone_id = aws_route53_zone.disk0401_net.id
  name    = "${each.key}.disk0401.net"
  type    = "A"
  ttl     = 172800
  records = [each.value.ipv4]
}

resource "aws_route53_record" "disk0401_net_white_label_ns_aaaa" {
  for_each = local.disk0401_net_white_label_ns

  zone_id = aws_route53_zone.disk0401_net.id
  name    = "${each.key}.disk0401.net"
  type    = "AAAA"
  ttl     = 172800
  records = [each.value.ipv6]
}

resource "aws_route53_record" "disk0401_net_ns" {
  allow_overwrite = true
  zone_id         = aws_route53_zone.disk0401_net.id
  name            = "disk0401.net"
  type            = "NS"
  ttl             = 172800
  records         = [for k in keys(local.disk0401_net_white_label_ns) : "${k}.disk0401.net"]

  depends_on = [
    aws_route53_record.disk0401_net_white_label_ns_a,
    aws_route53_record.disk0401_net_white_label_ns_aaaa,
  ]
}

import {
  to = aws_route53domains_registered_domain.disk0401_net
  id = "disk0401.net"
}

resource "aws_route53domains_registered_domain" "disk0401_net" {
  provider    = aws.us_east_1
  domain_name = "disk0401.net"

  dynamic "name_server" {
    for_each = local.disk0401_net_white_label_ns
    content {
      name     = "${name_server.key}.disk0401.net"
      glue_ips = [name_server.value.ipv4, name_server.value.ipv6]
    }
  }

  depends_on = [
    aws_route53_record.disk0401_net_white_label_ns_a,
    aws_route53_record.disk0401_net_white_label_ns_aaaa,
  ]
}
