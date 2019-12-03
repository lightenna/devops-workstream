variable "aws_region" {
}

variable "aws_ami" {
}

variable "aws_security_group_id" {
}

variable "aws_subnet_id" {
}

variable "bastion_host" {
}

variable "host_name" {
}

variable "local_domain" {
  description = "Name of the domain used locally in this environment"
  default     = "localdomain"
}

variable "key_name" {
  description = "Desired name of AWS key pair"
  default     = "devops_simple_key"
}

variable "docker_yum_repo_url" {
  description = "Location of Docker repository"
  default     = "https://download.docker.com/linux/centos/docker-ce.repo"
}

variable "docker_compose_binary_url_root" {
  description = "Partial location of docker-compose linux binary"
  default     = "https://github.com/docker/compose/releases/download/1.16.1/docker-compose"
}

