variable "domain_name" {
  type        = string
  default     = "thetechgirl.me"
  description = "Doman name"
}

resource "aws_route53_zone" "hosted_zone" {
    name = var.domain_name
    tags = {
        Environment = "dev"
    }
}

resource "aws_route53_record" "site_domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.Altschool-LB.dns_name
    zone_id                = aws_lb.Altschool-LB.zone_id
    evaluate_target_health = true
  }
}