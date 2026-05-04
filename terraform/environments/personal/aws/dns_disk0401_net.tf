resource "aws_route53_zone" "disk0401_net" {
  name = "disk0401.net"
}

resource "aws_route53_record" "disk0401_net_disk0401_net_a" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "disk0401.net"
  type    = "A"
  alias {
    name                   = "d1tmali2uve9f9.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "disk0401_net_disk0401_net_mx" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "disk0401.net"
  type    = "MX"
  ttl     = 300
  records = ["1 ASPMX.L.GOOGLE.COM.", "5 ALT1.ASPMX.L.GOOGLE.COM.", "5 ALT2.ASPMX.L.GOOGLE.COM.", "10 ALT3.ASPMX.L.GOOGLE.COM.", "10 ALT4.ASPMX.L.GOOGLE.COM."]
}

resource "aws_route53_record" "disk0401_net_disk0401_net_txt" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "disk0401.net"
  type    = "TXT"
  ttl     = 300
  records = ["\"_acme-challenge.disk0401.net.=NIPxl0bemV4ujBMBF5Zzlp83O-d7IQLGw7VOqwrdDpA\"", "\"google-site-verification=_KssjlmvFrJIURTHPHs9JegfDIc5y8-nAUldxj6BMwc\""]
}

resource "aws_route53_record" "disk0401_net_at_disk0401_net_txt" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "\\100.disk0401.net"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=spf1 include:_spf.google.com ~all\""]
}

resource "aws_route53_record" "disk0401_net__343d083f77da3f1897e6b18e40008044_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "_343d083f77da3f1897e6b18e40008044.disk0401.net"
  type    = "CNAME"
  ttl     = 300
  records = ["_2e184783ff81cb27989877a56f7b3958.wggjkglgrm.acm-validations.aws."]
}

resource "aws_route53_record" "disk0401_net__dmarc_disk0401_net_txt" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "_dmarc.disk0401.net"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=DMARC1; p=none; rua=mailto:dmarc-reports@disk0401.net\""]
}

resource "aws_route53_record" "disk0401_net_google__domainkey_disk0401_net_txt" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "google._domainkey.disk0401.net"
  type    = "TXT"
  ttl     = 3600
  records = ["\"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAkeGwFuJdVfBFo+rT3vgi/NmKN9/vJQCKZbdW9C/mRFoluoBLCx9ASwDlA3OF9kceXweAPfvN69f8n4JiQx+wk0na6i1GdZbFjgSPMcPlkPcK8/UEyVPjOSYZbtNoQjA+oJzoQfWi/W/oepKD/w9b5z/NxVWbrkX9F2oU+vwX5ggJ78oKqCjX1Z5j4LRtm0+ex\" \"OsmU5vD7dVv1RTQ3g6HzDQiLnJHfdRy8FpQ3nfn2XPYlVSxva/40nvzJL7VdS1FuVZFm0hFXEr6n041RoAjiBGITJZau55KKZuPI\" \"grWShjQhWhqUSUD4a0Ru1ujsZfPHlVhq0KbgMf19FC1W8UZnwIDAQAB\""]
}

resource "aws_route53_record" "disk0401_net_game_disk0401_net_a" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "game.disk0401.net"
  type    = "A"
  ttl     = 300
  records = [var.home_server_ip]
}

resource "aws_route53_record" "disk0401_net_grafana_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "grafana.disk0401.net"
  type    = "CNAME"
  ttl     = 300
  records = ["game.disk0401.net"]
}

resource "aws_route53_record" "disk0401_net_home_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "home.disk0401.net"
  type    = "CNAME"
  ttl     = 300
  records = ["game.disk0401.net"]
}

resource "aws_route53_record" "disk0401_net__amazonses_nas_disk0401_net_txt" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "_amazonses.nas.disk0401.net"
  type    = "TXT"
  ttl     = 1800
  records = ["\"z13097BdqT4oHWI1oCMccF3046q5NdwoSXkoHJVF9GM=\""]
}

resource "aws_route53_record" "disk0401_net_joh4yd3dpm3ke2nxjba5qhx5seyvu5ra__domainkey_nas_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "joh4yd3dpm3ke2nxjba5qhx5seyvu5ra._domainkey.nas.disk0401.net"
  type    = "CNAME"
  ttl     = 1800
  records = ["joh4yd3dpm3ke2nxjba5qhx5seyvu5ra.dkim.amazonses.com"]
}

resource "aws_route53_record" "disk0401_net_mjc6pkqfzqidqxhkk252qznwwd33tk5r__domainkey_nas_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "mjc6pkqfzqidqxhkk252qznwwd33tk5r._domainkey.nas.disk0401.net"
  type    = "CNAME"
  ttl     = 1800
  records = ["mjc6pkqfzqidqxhkk252qznwwd33tk5r.dkim.amazonses.com"]
}

resource "aws_route53_record" "disk0401_net_qz64ejxfgytnxcpjzofcwvbjd72kihtg__domainkey_nas_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "qz64ejxfgytnxcpjzofcwvbjd72kihtg._domainkey.nas.disk0401.net"
  type    = "CNAME"
  ttl     = 1800
  records = ["qz64ejxfgytnxcpjzofcwvbjd72kihtg.dkim.amazonses.com"]
}

resource "aws_route53_record" "disk0401_net_pve03_disk0401_net_cname" {
  zone_id = aws_route53_zone.disk0401_net.id
  name    = "pve03.disk0401.net"
  type    = "CNAME"
  ttl     = 300
  records = ["game.disk0401.net"]
}
