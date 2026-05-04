resource "aws_route53_zone" "citrus_media_studio" {
  name = "citrus-media.studio"
  comment = "HostedZone created by Route53 Registrar"
  force_destroy = false
}

resource "aws_route53_record" "citrus_media_studio_citrus_media_studio_mx" {
  zone_id = aws_route53_zone.citrus_media_studio.id
  name    = "citrus-media.studio"
  type    = "MX"
  ttl     = 300
  records = ["1 SMTP.GOOGLE.COM."]
}

resource "aws_route53_record" "citrus_media_studio_citrus_media_studio_txt" {
  zone_id = aws_route53_zone.citrus_media_studio.id
  name    = "citrus-media.studio"
  type    = "TXT"
  ttl     = 300
  records = ["google-site-verification=U-VIeNuXTTs9j67xZFlXOyjylwPQ_FEx73rGYXFHxXk"]
}

resource "aws_route53_record" "citrus_media_studio_ljdwzmhkuc2e_citrus_media_studio_cname" {
  zone_id = aws_route53_zone.citrus_media_studio.id
  name    = "ljdwzmhkuc2e.citrus-media.studio"
  type    = "CNAME"
  ttl     = 300
  records = ["gv-vygeeugtx3b6qn.dv.googlehosted.com"]
}
