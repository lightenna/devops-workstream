#
# create-aws-vm-puppetmastered
# OS support: CentOS
#

provider "aws" {}

locals {
  # STANDARD (puppetmastered, v1.0)
  home_directory = "${ var.admin_user == "root" ? "/root" : "/home/${var.admin_user}"}"
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_agent = "${local.puppet_exec} agent -dvt"
  setup_ssh_additional_port = "sudo /usr/sbin/semanage port -m -t ssh_port_t -p tcp ${var.ssh_additional_port} ; sudo sed -i 's/\\#Port 22/Port 22\\nPort ${var.ssh_additional_port}/g' /etc/ssh/sshd_config ; sudo service sshd restart"
  # /STANDARD (puppetmastered, v1.0), custom variables
  hostbase = "${var.hostname}-${terraform.workspace}-${var.project}-${var.account}"
}

# admin_password must be between 6-72 characters long and must satisfy at least 3 of password complexity requirements from the following: 1. Contains an uppercase character 2. Contains a lowercase character 3. Contains a numeric digit 4. Contains a special character
resource "random_string" "admin_password" {
  length = 12
  special = true
  # short list of special characters so double-click select works on password
  override_special = "-_"
  min_lower = 1
  min_upper = 1
  min_numeric = 1
  min_special = 1
}

resource "aws_instance" "puppetted_host" {
  connection {
    # indirect all requests via the bastion host
    bastion_host = "${var.bastion_public_ip}"
    bastion_port = "${var.bastion_ssh_port}"
    # connect from the bastion using our internal (private) IP, otherwise default to inaccessible public IP
    host = "${self.private_ip}"
    # default username for our AMI, connect using local SSH agent
    user = "centos"
  }

  # create a tiny instance
  instance_type = "${var.host_size}"

  # lookup the correct AMI based on the region
  ami = "${var.host_os_image}"

  # the name of our SSH keypair we created
  key_name = "${var.key_name}"

  vpc_security_group_ids = ["${var.nsg_id}"]
  subnet_id = "${var.subnet_id}"

  root_block_device {
    volume_type = "gp2" # general-purpose SSD
    volume_size = "8" # 8GB, 0.8 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = "${var.hostname}.${var.host_domain}"
  }

  #
  # STANDARD (puppetmastered, v1.0)
  #
  # wait for cloud provider to finish install its stuff, otherwise yum/dpkg collide [standard]
  provisioner "remote-exec" {
    inline = ["sleep 60"]
  }
  # run any host-specific commands [standard]
  provisioner "remote-exec" {
    inline = "${split(";", var.host_specific_commands)}"
  }
  # run install script to build host [standard]
  provisioner "remote-exec" {
    inline = [
      # deltarpm to reduce package manager work
      "sudo ${var.pkgman} -y install deltarpm",
      # install basic utilities
      "sudo ${var.pkgman} -y install wget curl unzip htop",
      # install semanage for SELinux
      "sudo ${var.pkgman} -y install policycoreutils-python",
      "sudo ${var.pkgman} -y update",
      "sudo ${var.pkgman} -y install puppet-agent",
      # set the hostname
      "sudo hostnamectl set-hostname ${var.hostname}.${var.host_domain}",
      # make SSH available on additional port, only if set
      "${var.ssh_additional_port == "22" ? "echo no_additional_port" : local.setup_ssh_additional_port}",
    ]
  }
  # copy puppet.conf file across to set up puppet agent to point to puppetmaster
  provisioner "file" {
    destination = "/etc/puppetlabs/puppet/puppet.conf"
    content = "${data.template_file.puppet_conf.rendered}"
  }
  # run puppet agent to generate cert request to puppetmaster
  provisioner "remote-exec" {
    inline = [
      # run puppet to create (as yet) unsigned key, ignore errors
      "sudo ${local.puppet_exec} agent -dvt > cert_req_puppet_agent.out 2>&1 || true",
    ]
  }
  # sign cert request locally (on puppetmaster, as root)
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca sign --certname ${var.hostname}.${var.host_domain}"
  }
  # run puppet agent
  provisioner "remote-exec" {
    inline = [
      # set the admin user's password
      "sudo bash -c \"echo -e '${random_string.admin_password.result}\n${random_string.admin_password.result}' | passwd ${var.admin_user}\"",
      # add admin user to wheel group to allow passworded sudo (redundant for root)
      "sudo usermod -aG wheel ${var.admin_user}",
      # run puppet mastered; this is time-consuming so don't wait to complete
      "sudo bash -c 'nohup ${local.puppet_agent} > ${local.home_directory}/puppet_agent.out & 2>&1'", #
      # wait a few seconds, then show a snippet from the run
      "sleep 6",
      "tail -n100 ${local.home_directory}/puppet_agent.out",
    ]
  }
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca clean --certname ${var.hostname}.${var.host_domain}; sudo ${local.puppet_exec} node deactivate ${var.hostname}.${var.host_domain}"
    on_failure = "continue"
    when = "destroy"
  }
  # /STANDARD (puppetmastered, v1.0)
}
# render a local template file for puppet.conf
data "template_file" "puppet_conf" {
  template = file("${path.module}/templates/puppet.conf.tpl")
  vars = {
    puppet_environment = "${var.puppet_environment}"
    puppet_master_fqdn = "${var.puppet_master_fqdn}"
    puppet_certname = "${var.hostname}.${var.host_domain}"
  }
}
