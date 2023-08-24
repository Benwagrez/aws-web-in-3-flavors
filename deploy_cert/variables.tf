variable "region" {
    type = string
}

variable "AWS_ACCESS_KEY_ID" {

}

variable "AWS_SECRET_ACCESS_KEY" {

}

variable "AWS_HOSTED_ZONE_ID" {

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