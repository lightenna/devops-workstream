
variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/id_rsa_devops_simple_key.pub
DESCRIPTION
  default = "~/.ssh/id_rsa_devops_simple_key.pub"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "devops_simple_key"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  # default to London
  default     = "eu-west-2"
}

variable "aws_ami" {
  # Ubuntu 16.04 LTS
  # default = "ami-03998867"
  # CentOS 7
  default = "ami-c22236a6"
}

