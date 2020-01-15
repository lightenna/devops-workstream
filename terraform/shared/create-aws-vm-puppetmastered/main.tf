#
# create-aws-vm-puppetmastered
# OS support: CentOS
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmastered, v1.8)
  puppet_exec = "/opt/puppetlabs/bin/puppet"
  puppet_server_exec = "/opt/puppetlabs/bin/puppetserver"
  puppet_run = "${local.puppet_exec} agent -t"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmastered, v1.6), custom variables
  real_bastion_public_ip = var.bastion_public_ip == "" ? aws_instance.puppetted_host.public_ip : var.bastion_public_ip
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
    bastion_host = var.bastion_public_ip == "" ? self.public_ip : var.bastion_public_ip
    bastion_user = local.real_bastion_user
    bastion_port = var.bastion_ssh_port
    # connect from the bastion using our internal (private) IP, otherwise use public IP
    host = var.bastion_use_external ? self.public_ip : self.private_ip
    # default username for our AMI, connect using local SSH agent
    user = var.admin_user
  }

  # create a tiny instance
  instance_type = var.host_size

  # lookup the correct AMI based on the region
  ami = var.host_os_image

  # the name of our SSH keypair we created
  key_name = var.ssh_key_name

  vpc_security_group_ids = [var.nsg_id]
  subnet_id = var.subnet_id

  # assign instance profile if set
  iam_instance_profile = var.iam_instance_profile

  root_block_device {
    volume_type = "gp2" # general-purpose SSD
    volume_size = var.volume_size # cost = size / 10 * $1.16/month EBS storage cost
    delete_on_termination = "true"
  }

  # tag for testing purposes
  tags = {
    Name = "${var.hostname}.${var.host_domain}"
  }
  #
  # STANDARD (puppetmastered, v1.8)
  #
  # upload facts
  provisioner "file" {
    destination = "/tmp/puppet-facts.yaml"
    content = templatefile("../../shared/create-x-vm-shared/templates/ext-facts.yaml.tmpl", {
      facts: var.facts
    })
  }
  # upload puppet.conf, install puppet, kick off cert_request, kick off cert_request
  provisioner "file" {
    destination = "/tmp/puppet-additions.conf"
    content = data.template_file.puppet_conf.rendered
  }
  provisioner "remote-exec" {
    inline = [templatefile("../../shared/create-x-vm-shared/templates/puppetmastered_certreq.sh.tmpl", {
      host_specific_commands: var.host_specific_commands,
      pkgman: var.pkgman,
      hostname: var.hostname,
      host_domain: var.host_domain,
      ssh_additional_port: var.ssh_additional_port,
      admin_user: var.admin_user,
      admin_password: random_string.admin_password.result,
      puppet_exec: local.puppet_exec,
    })]
  }
  # sign cert request locally (on puppetmaster, as root)
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca sign --certname ${var.hostname}.${var.host_domain}"
  }
  # run puppet agent
  provisioner "remote-exec" {
    inline = [templatefile("../../shared/create-x-vm-shared/templates/puppet_run.sh.tmpl", {
      puppet_mode: var.puppet_mode,
      puppet_run: local.puppet_run,
      puppet_sleeptime: var.puppet_sleeptime,
    })]
  }
  # when destroying this resource, clean the old certs off the puppet master
  provisioner "local-exec" {
    command = "sudo ${local.puppet_server_exec} ca clean --certname ${var.hostname}.${var.host_domain}; sudo ${local.puppet_exec} node deactivate ${var.hostname}.${var.host_domain}"
    on_failure = continue
    when = destroy
  }
  # /STANDARD (puppetmastered, v1.8)
}

# render a local template file for puppet.conf
data "template_file" "puppet_conf" {
  template = file("${path.module}/templates/puppet.conf.tpl")
  vars = {
    puppet_environment = var.puppet_environment
    puppet_master_fqdn = var.puppet_master_fqdn
    puppet_certname = "${var.hostname}.${var.host_domain}"
  }
}

# work out which DNS zone we're placing this DNS entry in
data "aws_route53_zone" "domain" {
  name = var.host_domain
  count = (var.create_dns_entry == "yes" ? 1 : 0)
}

# create an A record for easy access
resource "aws_route53_record" "a_record" {
  zone_id = data.aws_route53_zone.domain.0.zone_id
  type = "A"
  name = "${var.hostname}.${var.host_domain}"
  records = [aws_instance.puppetted_host.public_ip]
  # set short TTL
  ttl = "300"
  count = (var.create_dns_entry == "yes" ? 1 : 0)
}
