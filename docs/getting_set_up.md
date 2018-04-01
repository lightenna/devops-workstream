Workstream
==========

Getting set up
--------------

Install the pre-requisites [python](https://www.python.org/downloads/), pip (comes with Python > 2.7.9 or > 3.4), [awscli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html), [terraform](https://www.terraform.io/intro/getting-started/install.html), [terragrunt](https://github.com/gruntwork-io/terragrunt), [packer](https://www.packer.io/intro/getting-started/install.html) and optionally install [virtualenv](https://virtualenv.pypa.io/en/stable/installation/), [aws-shell](https://github.com/awslabs/aws-shell) with pip.

Set up an [automatically loaded SSH agent](http://mah.everybody.org/docs/ssh) or just run `ssh-agent` to create a temporary agent for the duration of this login.  If you'd like help with the pre-requisites, there's a [guide here](/docs/pre_requisites.md) for linux (CentOS 7).

Alternatively all the pre-requisites are installed on a publicly accessible AMI.  The follow instructions that explain [how to instantiate a VM using the Remote Provisioning machine image](/docs/remote_provisioning.md) (`workstation-remprov`).

Create an AWS credentials file.  This can be done using `aws configure` or manually creating a file in your home directory (e.g. `/home/your-username/.aws/credentials` or `/Users/your-username/.aws/credentials`) containing your access and secret keys:
```
[default]
aws_secret_access_key = <secret key>
aws_access_key_id = <access key>
region = eu-west-2
```

Restrict file access to your user using `chmod 0600 ~/.aws/credentials`

Check that you've got access to your AWS account:
```
aws ec2 describe-instances
```

Set up permissions for that AWS account to run these examples.  You can do this as widely or as narrowly as you'd like for your experiment, but the [AWS Permissions guide](/docs/aws_permissions.md) gives you a simple, fairly-open example set.

Create an SSH key and when prompted save it in `~/.ssh/id_rsa_devops_simple_key`:
```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Load the key you've created into your ssh-agent.
```
ssh-add ~/.ssh/id_rsa_devops_simple_key
```
Clone this repo (`git clone https://github.com/lightenna/devops-workstream.git`), then change directory into ```./terraform``` within it.

Initialise terraform:
```
terraform get
terraform init
```

Prepare your terraform calls.  Each will take the form:
```
terraform <action> <vars>
```
All calls beyond this point require a few variables to be set unless you use the defaults:
```
-var 'aws_region=eu-west-2' \
-var 'key_name=devops_simple_key' \
-var 'public_key_path=~/.ssh/id_rsa_devops_simple_key.pub'
```
or set them in an `.aws/config` file like:
```
[default]
region = eu-west-2
```
so a typical call, abbreviated to `terraform plan` because we're using the default values would look like
```
terraform plan -var 'aws_region=eu-west-2' -var 'key_name=devops_simple_key' -var 'public_key_path=~/.ssh/id_rsa_devops_simple_key.pub'
```

I'm using the `terraform plan` syntax here, but you're better using the wrapper `terragrunt plan` if you've got it installed.
