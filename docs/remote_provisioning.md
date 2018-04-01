Workstream
==========

Remote provisioning
--------------

Within the [Packer folder](/packer) is a JSON template (`remote_provisioning.md`) that builds an Amazon Machine Image (AMI) called `remprov`.  If your local machine is difficult to set up, or unsuitable for running a provisioning service (like Terraform), you might choose to work remotely.  Follow these instructions to create and access a VM for remote provisioning.

Machine Image (`workstream-remprov`)
-------------

* Based on CentOS 7.
* Contains all the code in this repository (`~/workstream`).
* Has all the pre-requisites installed along the lines defined in the [CentOS 7 guide](/docs/pre_requisites.md).

Instructions
------------

1.  Create key pair
    * private key (`.pem`) may need converting using a tool like `PuttyGen` into a `.ppk` file for use with Putty
2.  Create Instance
    * select "Community AMIs"
    * search for and select "workspace-remprov"
    * select the key pair you created in step #1
    * note public IP address
3.  Load SSH key into local key agent, or point SSH client at private key file.
4.  SSH into newly created instance and complete setup
    * use default user (`centos`) and private key from step #1
    * [Getting set up guide](/docs/getting_set_up.md) covers configuring AWS credentials
    
