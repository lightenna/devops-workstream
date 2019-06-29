#
# Output variables for other modules to use
#
output "aws_key_pair_id" {
  value = "${aws_key_pair.auth.id}"
}

output "aws_security_group_id" {
  value = "${aws_security_group.simple.id}"
}

output "aws_vpc_id" {
  value = "${aws_vpc.default.id}"
}

output "aws_subnet_id" {
  value = "${aws_subnet.default.id}"
}

output "aws_bastion_public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

output "aws_ami_id" {
  value = "${aws_instance.bastion.ami}"
}
