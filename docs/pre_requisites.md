Workstream
==========

Pre-requisites
--------------

Here are the install instructions for CentOS 7/RHEL 7 (and a bit of help for [Mac OS X](/docs/pre_requisites_macosx.md)).

Install python34 (in addition to system python27)

`sudo yum install epel-release wget unzip`

`sudo yum install python34`

Check the system python is still 2.7.5

`whereis python`

`python --version`

Manually download virtualenv

`curl -O https://pypi.python.org/packages/source/v/virtualenv/virtualenv-13.1.2.tar.gz`

`tar xvfz virtualenv-13.1.2.tar.gz`

`cd virtualenv-13.1.2`

`sudo /usr/bin/python3.4 setup.py install`

Create and activate a virtualenv called mave in your home directory

`cd ~`

`virtualenv mave`

`source ./mave/bin/activate`

You'll need to source the activate script everytime you log into this machine or from your .bash_profile

Install awscli using pip (included in python 3.4)

`pip install awscli --upgrade`

`pip install aws-shell`

Install Terraform and Packer.

`wget -O terraform_0.11.1_linux_amd64.zip https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip?_ga=2.124076492.730183970.1512483429-1357698916.1512127611`

`unzip terraform_0.11.1_linux_amd64.zip`

`sudo mv ./terraform /usr/local/bin ; sudo chown root:root /usr/local/bin/terraform ; sudo chmod 755 /usr/local/bin/terraform`

`wget -O packer_1.1.0_linux_amd64.zip https://releases.hashicorp.com/packer/1.1.0/packer_1.1.0_linux_amd64.zip?_ga=2.68251096.896084704.1507823238-2016154149.1507030560`

`unzip packer_1.1.0_linux_amd64.zip`

`sudo mv ./packer /usr/local/bin ; sudo chown root:root /usr/local/bin/packer ; sudo chmod 755 /usr/local/bin/packer`

Install Terragrunt

`curl -o terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.14.6/terragrunt_linux_amd64`

`chmod a+x terragrunt`

`mv terragrunt /usr/local/bin/`

## Versions

Versions are constantly moving forward and many companies don't provide a 'head' link.  You can get links to the latest version directly from the [Hashicorp website](https://www.hashicorp.com/) or googling the tool name (e.g. Virtualenv or Terragrunt).
