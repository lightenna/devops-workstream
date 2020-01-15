#
# create-aws-vm-puppetmless
# OS support: CentOS
#

# default provider configured in root (upstream) module

locals {
  # STANDARD (puppetmless, v1.8)
  puppet_target_repodir = "/etc/puppetlabs/puppetmless"
  puppet_source = "${path.module}/../../../puppet"
  puppet_run = "/opt/puppetlabs/bin/puppet apply -t --hiera_config=${local.puppet_target_repodir}/environments/${var.puppet_environment}/hiera.yaml --modulepath=${local.puppet_target_repodir}/modules:${local.puppet_target_repodir}/environments/shared/modules:${local.puppet_target_repodir}/environments/${var.puppet_environment}/modules ${local.puppet_target_repodir}/environments/${var.puppet_environment}/manifests/${var.puppet_manifest_name}"
  real_bastion_user = var.bastion_user == "" ? var.admin_user : var.bastion_user
  # /STANDARD (puppetmless, v1.8), custom variables
  real_bastion_public_ip = var.bastion_public_ip == "" ? aws_instance.puppetted_host.public_ip : var.bastion_public_ip
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

  # upload facts
  provisioner "file" {
    destination = "/tmp/puppet-facts.yaml"
    content = templatefile("../../shared/create-x-vm-shared/templates/ext-facts.yaml.tmpl", {
      facts: var.facts
    })
  }
  # upload puppet manifests and puppet
  provisioner "file" {
    source = local.puppet_source
    # transfer to intermediary folder
    destination = "/tmp/puppet-additions"
    # can't go straight to final destination because user doesn't have access
    # and "file" provisioners have no sudo escalation
  }
  provisioner "remote-exec" {
    inline = [
      templatefile("../../shared/create-x-vm-shared/templates/puppetmless.sh.tmpl", {
        host_specific_commands: var.host_specific_commands,
        pkgman: var.pkgman,
        hostname: var.hostname,
        host_domain: var.host_domain,
        ssh_additional_port: var.ssh_additional_port,
        admin_user: var.admin_user,
        admin_password: random_string.admin_password.result,
        puppet_target_repodir: local.puppet_target_repodir,
      }),
      templatefile("../../shared/create-x-vm-shared/templates/puppet_run.sh.tmpl", {
        puppet_mode: var.puppet_mode,
        puppet_run: local.puppet_run,
        puppet_sleeptime: var.puppet_sleeptime,
      })
    ]
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
