data "aws_route53_zone" "zone" {
  name         = "${var.zone_name}."
  private_zone = false
}


resource "aws_acm_certificate" "vault" {
  domain_name       = "${var.prefix}${var.app_name}${var.suffix}.${var.zone_name}"
  validation_method = "DNS"
  subject_alternative_names = [
    "${var.prefix}${var.app_name2}${var.suffix}.${var.zone_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name}${var.suffix}-acm"),
  )

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}


resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.vault.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}


resource "aws_acm_certificate_validation" "vault" {
  certificate_arn         = aws_acm_certificate.vault.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_route53_record" "cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.prefix}${var.app_name}${var.suffix}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_alb.main.dns_name]
}



// Consul
resource "aws_acm_certificate" "consul" {
  domain_name       = "${var.prefix}${var.app_name2}${var.suffix}.${var.zone_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.extra_tags,
    map("Name", "${var.environment}-${var.prefix}${var.app_name2}${var.suffix}-acm"),
  )
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}


resource "aws_route53_record" "consul_validation" {
  for_each = {
    for dvo in aws_acm_certificate.consul.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}


resource "aws_acm_certificate_validation" "consul" {
  certificate_arn         = aws_acm_certificate.consul.arn
  validation_record_fqdns = [for record in aws_route53_record.consul_validation : record.fqdn]
}



resource "aws_route53_record" "consul_cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${var.prefix}${var.app_name2}${var.suffix}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_alb.main.dns_name]
}




// resource "tls_private_key" "consul-ca" {
//   algorithm = "RSA"
//   rsa_bits  = "2048"
// }

// resource "tls_self_signed_cert" "consul-ca" {
//   key_algorithm   = tls_private_key.consul-ca.algorithm
//   private_key_pem = tls_private_key.consul-ca.private_key_pem

//   subject {
//     common_name  = "consul.local"
//     organization = "Consul"
//   }

//   validity_period_hours = 8760
//   is_ca_certificate     = true

//   allowed_uses = [
//     "cert_signing",
//     "digital_signature",
//     "key_encipherment",
//   ]
// }

// resource "tls_private_key" "consul" {
//   algorithm = "RSA"
//   rsa_bits  = "2048"
// }

// resource "tls_cert_request" "consul" {
//   key_algorithm   = tls_private_key.consul.algorithm
//   private_key_pem = tls_private_key.consul.private_key_pem

//   dns_names = [
//     "vault",
//     "consul",
//     "vault.local",
//     "consul.local",
//     "vault.default.svc.cluster.local",
//     "consul.default.svc.cluster.local",
//     "localhost",
//     "127.0.0.1",
//   ]

//   subject {
//     common_name  = "consul.local"
//     organization = "Consul"
//   }
// }

// resource "tls_locally_signed_cert" "consul" {
//   cert_request_pem = tls_cert_request.consul.cert_request_pem

//   ca_key_algorithm   = tls_private_key.consul-ca.algorithm
//   ca_private_key_pem = tls_private_key.consul-ca.private_key_pem
//   ca_cert_pem        = tls_self_signed_cert.consul-ca.cert_pem

//   validity_period_hours = 8760

//   allowed_uses = [
//     "cert_signing",
//     "client_auth",
//     "digital_signature",
//     "key_encipherment",
//     "server_auth",
//   ]
// }


// tls_self_signed_cert.consul-ca.cert_pem
// tls_private_key.consul-ca.private_key_pem
