
data "aws_route53_zone" "main" {
  name         = "${local.root_domain}."
  private_zone = false
}

