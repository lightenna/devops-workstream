variable "compartment_ocid" {}

variable "project" {
  default = "projname"
}

variable "account" {
  default = "orgname"
}

variable "hostname" {
  default = "generic"
}

variable "region" {
  default = "uk-london-1"
}

variable "region_ad" {
  # was 1, but 2 seems to be free eligible
  default = "2"
}

variable "pkgman" {
  default = "yum"
}

variable "host_specific_commands" {
  type = string
  description = "semi-colon (;) separated list of strings"
  default = "sudo yum -y install epel-release;sudo rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm"
}

variable "host_domain" {
  default = "localdomain"
}

variable "host_os_image" {
  type = map(string)

  default = {
    # Install Oracle 7.x [default]
    #  + see https://docs.cloud.oracle.com/iaas/images/image/cc839b42-1566-4d87-92c3-dbb5945299c7/
    uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaagwdcgcw4squjusjy4yoyzxlewn6omj75f2xur2qpo7dgwexnzyhq"

    # Install CentOS 7.x
    #  + see https://docs.cloud.oracle.com/iaas/images/image/e090db79-477b-4d8b-92bc-f3485e6ed09d/
    # uk-london-1 = "ocid1.image.oc1.uk-london-1.aaaaaaaabf2eslezq4wejiu3kq7zbbbmkw5k55eltwmpgpgzju2t7q3nlx7q"
  }
}

variable "host_size" {
  # default = "VM.Standard2.1"
  default = "VM.Standard.E2.1.Micro"
}

variable "host_tags" {
  type = map(string)
  description = "semi-colon (;) separated list of strings"
  default = {}
}

variable "volume_size" {
  default = "50"
}

variable "admin_user" {
  # terraform runs as admin_user, sudos to run puppet as root
  default = "opc"
}

variable "public_key_path" {}
variable "subnet_id" {}

variable "bastion_public_ip" {
  # no explicit bastion ip, don't use a bastion
  default = ""
}
variable "bastion_user" {
  default = ""
}
variable "bastion_ssh_port" {
  default = "22"
}

variable "ssh_additional_port" {
  # port 22 to indicate no additional port
  default = "22"
}

variable "puppet_mode" {
  default = "fire-and-forget"
}

variable "puppet_sleeptime" {
  default = 120
}

variable "puppet_environment" {
  default = "prod"
}

variable "puppet_manifest_name" {
  # empty to evaluate the whole puppet directory
  default = ""
}

variable "create_dns_entry" {
  default = "no"
}

variable "dns_resource_group_name" {
  # dns_resource_group_name required if create_dns_entry is yes
  default = ""
}

variable "facts" {
  default = {}
}

## sensible Oracle-specific defaults

variable "num_instances" {
  default = "1"
}

variable "num_iscsi_volumes_per_instance" {
  default = "0"
}

variable "num_paravirtualized_volumes_per_instance" {
  default = "1"
}
