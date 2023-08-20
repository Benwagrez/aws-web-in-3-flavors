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