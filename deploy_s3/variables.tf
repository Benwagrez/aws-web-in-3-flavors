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
  description = "Certificate for ALB that verifies domain name"
}