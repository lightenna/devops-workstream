#!/usr/bin/env python2
repo_root='../../../'
import sys, os
sys.path.append(os.path.join(os.path.dirname(__file__), repo_root + 'python', 'shared'))
import subprocess
import shlex

packer_root_relative='./'
packer_template='remote_provisioning.json'
# us-east-1 (use in preference for AWS Marketplace image creation)
aws_subnet_id='subnet-0704d28e923306198'
aws_vpc_id='vpc-09af3f9e55a611c1f'
aws_region='us-east-1'
# eu-west-2 (deprecated)
# aws_subnet_id='subnet-07695f52612b62f94'
# aws_vpc_id='vpc-0eaa632e3dfdb1eb0'

# Main
# build packer image from packer root
# os.environ['PACKER_LOG'] = "1"
packer_command=("packer build -var 'aws_subnet_id={aws_subnet_id}' -var 'aws_vpc_id={aws_vpc_id}' -var 'aws_region={aws_region}' --force {packer_template}".format(
    aws_subnet_id=aws_subnet_id, aws_vpc_id=aws_vpc_id, aws_region=aws_region, packer_template=packer_template))
print(packer_command)
subprocess.call(shlex.split(packer_command), shell=True, cwd=os.path.abspath(packer_root_relative))
