#
# create-oraclecloud-vm-puppetmless
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

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.compartment_ocid
  ad_number = var.region_ad
}

resource "oci_core_instance" "instance" {
  count = var.num_instances
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id = var.compartment_ocid
  display_name = "${count.index > 0 ? count.index : ""}${var.hostname}.${var.host_domain}"
  shape = var.host_size

  create_vnic_details {
    subnet_id = var.subnet_id
    display_name = "primaryvnic"
    assign_public_ip = true
    hostname_label = "${count.index > 0 ? count.index : ""}${var.hostname}"
  }

  source_details {
    source_type = "image"
    source_id = var.host_os_image[var.region]
    # Apply this to set the size of the boot volume that's created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    #boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true

  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
    # user_data           = base64encode(file("./userdata/bootstrap"))
  }
  defined_tags = var.host_tags

  freeform_tags = {
    "freeformkey${count.index}" = "freeformvalue${count.index}"
  }
  timeouts {
    create = "60m"
  }
}

#
# Volumes
#

resource "oci_core_volume" "block_volume" {
  count = var.num_instances * var.num_iscsi_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id = var.compartment_ocid
  display_name = "vBlock${count.index}"
  size_in_gbs = var.volume_size
}

resource "oci_core_volume_attachment" "block_attach" {
  count = var.num_instances * var.num_iscsi_volumes_per_instance
  attachment_type = "iscsi"
  instance_id = oci_core_instance.instance[floor(count.index / var.num_iscsi_volumes_per_instance)].id
  volume_id = oci_core_volume.block_volume[count.index].id
  device = count.index == 0 ? "/dev/oracleoci/oraclevdb" : ""

  # Set this to enable CHAP authentication for an ISCSI volume attachment. The oci_core_volume_attachment resource will
  # contain the CHAP authentication details via the "chap_secret" and "chap_username" attributes.
  use_chap = true
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

resource "oci_core_volume" "block_volume_paravirtualized" {
  count = var.num_instances * var.num_paravirtualized_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id = var.compartment_ocid
  display_name = "vBlockParavirtualized${count.index}"
  size_in_gbs = var.volume_size
}

resource "oci_core_volume_attachment" "block_volume_attach_paravirtualized" {
  count = var.num_instances * var.num_paravirtualized_volumes_per_instance
  attachment_type = "paravirtualized"
  instance_id = oci_core_instance.instance[floor(count.index / var.num_paravirtualized_volumes_per_instance)].id
  volume_id = oci_core_volume.block_volume_paravirtualized[count.index].id
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

#resource "oci_core_volume_backup_policy_assignment" "policy" {
#  count = 2
#  asset_id = oci_core_instance.instance[count.index].boot_volume_id
#  policy_id = data.oci_core_volume_backup_policies.predefined_volume_backup_policies.volume_backup_policies[0].id
#}

resource "null_resource" "remote-exec-iscsi" {
  depends_on = [
    oci_core_instance.instance,
    oci_core_volume_attachment.block_attach,
  ]
  count = var.num_instances * var.num_iscsi_volumes_per_instance

  provisioner "remote-exec" {
    connection {
      timeout = "30m"
      type = "ssh"
      user = var.admin_user
      bastion_host = var.bastion_public_ip
      bastion_port = var.bastion_ssh_port
      bastion_user = local.real_bastion_user
      host = oci_core_instance.instance[count.index % var.num_instances].public_ip
      port = "22"
    }

    inline = [
      "touch ~/IMadeAFile.Right.Here",
      "sudo iscsiadm -m node -o new -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -p ${oci_core_volume_attachment.block_attach[count.index].ipv4}:${oci_core_volume_attachment.block_attach[count.index].port}",
      "sudo iscsiadm -m node -o update -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -n node.startup -v automatic",
      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -p ${oci_core_volume_attachment.block_attach[count.index].ipv4}:${oci_core_volume_attachment.block_attach[count.index].port} -o update -n node.session.auth.authmethod -v CHAP",
      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -p ${oci_core_volume_attachment.block_attach[count.index].ipv4}:${oci_core_volume_attachment.block_attach[count.index].port} -o update -n node.session.auth.username -v ${oci_core_volume_attachment.block_attach[count.index].chap_username}",
      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -p ${oci_core_volume_attachment.block_attach[count.index].ipv4}:${oci_core_volume_attachment.block_attach[count.index].port} -o update -n node.session.auth.password -v ${oci_core_volume_attachment.block_attach[count.index].chap_secret}",
      "sudo iscsiadm -m node -T ${oci_core_volume_attachment.block_attach[count.index].iqn} -p ${oci_core_volume_attachment.block_attach[count.index].ipv4}:${oci_core_volume_attachment.block_attach[count.index].port} -l",
    ]
  }
}

# Gets the boot volume attachments for each instance
data "oci_core_boot_volume_attachments" "boot_volume_attachments" {
  depends_on = [
    oci_core_instance.instance]
  count = var.num_instances
  availability_domain = oci_core_instance.instance[count.index].availability_domain
  compartment_id = var.compartment_ocid

  instance_id = oci_core_instance.instance[count.index].id
}

data "oci_core_instance_devices" "instance_devices" {
  count = var.num_instances
  instance_id = oci_core_instance.instance[count.index].id
}

data "oci_core_volume_backup_policies" "predefined_volume_backup_policies" {
  filter {
    name = "display_name"

    values = [
      "silver",
    ]
  }
}

#
# Puppet
#

resource "null_resource" "remote-exec-puppetmless" {
  depends_on = [
    oci_core_instance.instance,
    oci_core_volume_attachment.block_attach,
  ]
  count = var.num_instances * var.num_iscsi_volumes_per_instance

  connection {
    timeout = "30m"
    type = "ssh"
    user = var.admin_user
    bastion_host = var.bastion_public_ip
    bastion_port = var.bastion_ssh_port
    bastion_user = local.real_bastion_user
    host = oci_core_instance.instance[count.index % var.num_instances].public_ip
    port = "22"
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
  # install and execute puppet
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

# create new A record
resource "oci_dns_record" "dynamic_a_record" {
  zone_name_or_id = var.host_domain
  compartment_id = var.compartment_ocid
  domain = "${var.hostname}.${var.host_domain}"
  rtype = "A"
  rdata = oci_core_instance.instance[0].public_ip
  ttl = "300"
}
