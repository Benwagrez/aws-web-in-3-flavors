variable "common_tags" {
  type = map(string)
  description = "Commong tags to provision on resources created in Terraform"
  default = {
      Infra = "deploy_vm",
      Owner = "benwagrez@gmail.com"
  }
}

variable "domain_name" {
    type = string
}

variable "acm_cert" {
  type = string
  description = "Certificate for Cloud Front Distribution that verifies domain name"
}

variable "TerraformSPNArn" {
  type = string
  description = "Arn of the service principal deploying the Terraform code (user owner of access key)."
}