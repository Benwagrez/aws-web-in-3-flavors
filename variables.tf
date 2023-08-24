variable "deployvm" {
    type = bool
    default = false
}

variable "deployS3" {
    type = bool
    default = false
}

variable "deploycontainer" {
    type = bool
    default = false
}

variable "AWS_ACCESS_KEY" {
    type = string
}

variable "AWS_SECRET_KEY" {
    type = string
}

variable "VM_KEY_ID" {
    type = string
}

variable "domain_name" {
    type = string
}

variable "region" {
    type = string
}

variable "email_address" {
    type = string
}

variable "certificates" {
  type = list(object({
      common_name = string,
      subject_alternative_names = list(string),
      key_type = string,
      must_staple = string,
      min_days_remaining = string,
      certificate_p12_password = string
    })
  )
}

variable "hosted_zone_id" {
    type = string
}