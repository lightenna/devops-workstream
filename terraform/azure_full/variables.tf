
variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/id_rsa_devops_simple_key.pub
DESCRIPTION
  default = "~/.ssh/id_rsa_devops_simple_key.pub"
}

variable "unique_id" {
  default = ""
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "devops_simple_key"
}

variable "project" {
  default = "wrks"
}

variable "account" {
  default = "dvo"
}

variable "subnet_prepend" {
  default = "10.0.52"
}

variable "ssh_additional_port" {
  default = 443
}

variable "admin_user" {
  default = "rootlike"
}
