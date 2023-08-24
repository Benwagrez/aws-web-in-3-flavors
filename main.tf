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


# Configure the Providers

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

provider "tls" {}

provider "aws" {
  region = var.region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}



# Module calls

module "SSL_certification_deployment" {
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
  domain_name = var.domain_name
  record = var.deployS3 ? null : var.deployvm ? [ module.vm_website_deployment[0].vm_publicip ] : var.deploycontainer ? null : null
  zone_id = var.hosted_zone_id
}

module "S3_website_deployment" {
  count = var.deployS3 ? 1 : 0
  source = "./deploy_s3"
} 

module "vm_website_deployment" {
  count = var.deployvm ? 1 : 0
  source = "./deploy_vm"

  AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  VM_KEY_ID = var.VM_KEY_ID
}

module "container_website_deployment" {
  count = var.deploycontainer ? 1 : 0
  source = "./deploy_container"
}