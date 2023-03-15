resource "aws_route53_record" "application_a_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.webapp.public_ip]
}
