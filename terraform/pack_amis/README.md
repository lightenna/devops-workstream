Workstream
==========

Pack AMIs
---------
`/terraform/pack_amis` is a simple terraform submodule that runs Packer to build an Amazon machine image (AMI).

Getting started
---------------

The pre-requisites for this submodule are broadly identical to the pre-requisites for this repo as a whole.

From the terraform root folder ([/terraform](./terraform)) run:

```terraform plan -var 'aws_region=eu-west-2' pack_amis```

then, if you're happy with the output

```terraform apply -var 'aws_region=eu-west-2' pack_amis```

As ever don't forget to clean up afterwards.  `terraform destroy` does not destroy the AMIs and Snapshots (intermediates) that Packer produces, so please use the AWS console to delete.

