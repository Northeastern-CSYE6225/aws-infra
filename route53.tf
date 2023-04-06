data "aws_route53_zone" "primary" {
  name = var.domain_name
}

# resource "aws_route53_record" "application_lb_cname" {
#   zone_id        = data.aws_route53_zone.primary.zone_id
#   name           = var.domain_name
#   type           = "A"
#   ttl            = 60
#   set_identifier = var.domain_name
#   records        = [aws_lb.lb.dns_name]
# }

resource "aws_route53_record" "application_lb_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}
