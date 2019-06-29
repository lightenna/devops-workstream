#
# Output variables for other modules to use
#
output "packed_ami_centos_updated_id" {
  value = "${data.aws_ami.centos_updated.id}"
}
