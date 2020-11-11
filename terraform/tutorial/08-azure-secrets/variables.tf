variable "project" {
  default = "sec"
}

variable "unique_id" {
  # set a default value to make these resources referencable (by default) from future tutorials
  default = "example"
}

variable "private_key_name" {
  default = "private_key.pkcs7.pem"
}

variable "public_key_name" {
  default = "public_key.pkcs7.pem"
}
