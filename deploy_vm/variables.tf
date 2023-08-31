variable "common_tags" {
  type = map(string)
  description = "Commong tags to provision on resources created in Terraform"
  default = {
      Infra = "deploy_vm",
      Owner = "benwagrez@gmail.com"
  }
}

variable "acm_cert" {
  type = string
  description = "Certificate for ALB that verifies domain name"
}

variable "VM_KEY_ID" {
  type = string
  description = "SSH key name that is provisioned on AWS"
}

variable "AWS_ACCOUNT_ID" {
  type = string
  description = "AWS Account ID"
}