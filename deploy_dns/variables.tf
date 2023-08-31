variable "record" {
  type = string
}

variable "record_zone"{
  type = string
}

variable "domain_name" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "deployvm" {
  type = bool
  default = false
}

# Variables for deploy S3
variable "deployS3" {
  type = bool
  default = false
}

variable "root_s3_distribution_domain_name" {
  type = string
}

variable "root_s3_distribution_hosted_zone_id" {
  type = string
}

variable "www_s3_distribution_domain_name" {
  type = string
}

variable "www_s3_distribution_hosted_zone_id" {
  type = string
}

# Veriables for deploy container
variable "deploycontainer" {
  type = bool
  default = false
}