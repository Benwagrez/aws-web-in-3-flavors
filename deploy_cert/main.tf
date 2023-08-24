

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
    acme = {
      source = "vancluever/acme"
      version = "2.16.1"
    }
  }
}

resource "tls_private_key" "registration" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.registration.private_key_pem
  email_address   = var.email_address

#   dynamic "external_account_binding" {
#     for_each = var.external_account_binding != null ? [null] : []
#     content {
#       key_id      = var.external_account_binding.key_id
#       hmac_base64 = var.external_account_binding.hmac_base64
#     }
#   }
}

resource "acme_certificate" "certificates" {
  for_each = { for certificate in var.certificates : index(var.certificates, certificate) => certificate }

  common_name               = each.value.common_name
  subject_alternative_names = each.value.subject_alternative_names
  key_type                  = each.value.key_type
  must_staple               = each.value.must_staple
  min_days_remaining        = each.value.min_days_remaining
  certificate_p12_password  = each.value.certificate_p12_password
  account_key_pem              = acme_registration.registration.account_key_pem
  recursive_nameservers        = [ "ns-1239.awsdns-26.org", "ns-1940.awsdns-50.co.uk", "ns-658.awsdns-18.net", "ns-88.awsdns-11.com" ]
  disable_complete_propagation = false
  pre_check_delay              = 0

  dns_challenge {
      provider = "route53"
      config   = {
        AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
        AWS_DEFAULT_REGION    = var.region
        AWS_HOSTED_ZONE_ID    = var.AWS_HOSTED_ZONE_ID
      }
    }
}

# Import the certificate into ACM

resource "aws_acm_certificate" "cert" {
  private_key        =  acme_certificate.certificates[0].private_key_pem   
  certificate_body   =  acme_certificate.certificates[0].certificate_pem 
  certificate_chain  =  acme_certificate.certificates[0].issuer_pem
  depends_on         =  [acme_certificate.certificates,tls_private_key.registration,acme_registration.registration]
}

# Upload to SSM (for EC2)

resource "aws_ssm_parameter" "key" {
  name        = "/octoweb/SSL/key"
  description = "Website Private Key"
  type        = "SecureString"
  value       = acme_certificate.certificates[0].private_key_pem   
}

resource "aws_ssm_parameter" "cert" {
  name        = "/octoweb/SSL/cert"
  description = "Website Certificate"
  type        = "SecureString"
  value       = acme_certificate.certificates[0].certificate_pem
}

resource "aws_ssm_parameter" "certchain" {
  name        = "/octoweb/SSL/certchain"
  description = "Website Certificate Chain"
  type        = "SecureString"
  value       = acme_certificate.certificates[0].issuer_pem
}