# ========================= #
# ===== Main Executor ===== #
# ========================= #
# Purpose
# Manage all instantiated modules and providers
#
# Notes
# This module manager gives a holistic view on the environment being deployed through IAC. It provides documentation,
# clear and concise variables, and is easy to read for the purposes of understanding the code in the repo.

locals {
  common_tags = {
    Infra = var.deployvm ? "deploy_Vm" : var.deploycontainer ? "deploy_container" : var.deployS3 ? "deploy_s3" : ""
    Owner = "benwagrez@gmail.com"
  }
}

#############################
###### Provider Config ######
#############################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    acme = {
      source = "vancluever/acme"
      version = "2.16.1"
    }
  }
}

# Acme provider for SSL certs for benwagrez.com
provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

# TLS provider for private key creation
provider "tls" {}

# AWS Provider
provider "aws" {
  region = var.region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

# Random module - TODO incorporate more randomness
provider "random" {
}


#############################
###### Module Manager #######
#############################
# Below module dependencies are listed #
# ------------------------------------ #
# SSL_certification_deployment | Required for all deployments
# DNS_deployment               | Required for all deployments (currently only VM has integration)
# S3_website_deployment        | For S3 deployment - Depends on deployS3 var
# vm_website_deployment        | For VM deployment - Depends on deployvm var
# container_website_deployment | For container deployment - Depends on deploycontainer var


module "SSL_certification_deployment" {
  providers = {
    aws.east = aws.east
  }
  source                = "./deploy_cert"

  region                = var.region
  email_address         = var.email_address
  AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY
  AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_KEY
  AWS_HOSTED_ZONE_ID    = module.DNS_deployment.hosted_zone_id
  certificates           = var.certificates
}

module "DNS_deployment" {
  source = "./deploy_dns"

  domain_name     = var.domain_name
  record          = var.deployS3 ? null : var.deployvm ? module.vm_website_deployment[0].app_gw_dns : var.deploycontainer ? null : null
  record_zone     = var.deployvm ? module.vm_website_deployment[0].app_gw_zone_id : null
  zone_id         = var.hosted_zone_id
  deployvm        = var.deployvm
  
  # S3 Module Vars
  deployS3        = var.deployS3
  root_s3_distribution_domain_name    = var.deployS3 ? module.S3_website_deployment[0].root_cloudfront_domain_name : null
  root_s3_distribution_hosted_zone_id = var.deployS3 ? module.S3_website_deployment[0].root_cloudfront_hosted_zone_id : null
  www_s3_distribution_domain_name     = var.deployS3 ? module.S3_website_deployment[0].www_cloudfront_domain_name : null
  www_s3_distribution_hosted_zone_id  = var.deployS3 ? module.S3_website_deployment[0].www_cloudfront_hosted_zone_id : null

  deploycontainer = var.deploycontainer
}

module "S3_website_deployment" {
  count = var.deployS3 ? 1 : 0
  source = "./deploy_s3"

  acm_cert = module.SSL_certification_deployment.acm_east_cert_arn
  domain_name = var.domain_name
  common_tags = local.common_tags
} 

module "vm_website_deployment" {
  count = var.deployvm ? 1 : 0
  source = "./deploy_vm"

  acm_cert = module.SSL_certification_deployment.acm_alb_cert_arn
  AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  VM_KEY_ID = var.VM_KEY_ID
  common_tags = local.common_tags
}

module "container_website_deployment" {
  count = var.deploycontainer ? 1 : 0
  source = "./deploy_container"
}
