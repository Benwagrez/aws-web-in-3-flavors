terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}


module "S3_website_deployment" {
  count = var.deployS3 ? 1 : 0
  source = "./deploy_s3"
} 

module "vm_website_deployment" {
  count = var.deployvm ? 1 : 0
  source = "./deploy_vm"

  VM_KEY_ID = var.VM_KEY_ID
}

module "container_website_deployment" {
  count = var.deploycontainer ? 1 : 0
  source = "./deploy_container"
}