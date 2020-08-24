require 'spec_helper'

# Cannot use the default awspec
#   `describe ec2('nametag') do`
# because it gets confused by as-yet-not-cleaned-up Terminated AWS instances.
# Instead use Tom Butler's patch
#   `EC2Helper.GetIdFromName('nametag')`

describe ec2(EC2Helper.GetIdFromName('bastion')) do
  it { should exist }
  it { should be_running }
  its(:image_id) { should eq 'ami-c22236a6' }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_bastion') }
end

describe ec2(EC2Helper.GetIdFromName('puppetmless')) do
  it { should exist }
  it { should be_running }
  its(:image_id) { should eq 'ami-c22236a6' }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_simple') }
end

describe ec2(EC2Helper.GetIdFromName('puppetmaster')) do
  it { should exist }
  it { should be_running }
  its(:image_id) { should eq 'ami-c22236a6' }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_simple') }
end

describe ec2(EC2Helper.GetIdFromName('ansiblelocal')) do
  it { should exist }
  it { should be_running }
  its(:image_id) { should eq 'ami-c22236a6' }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_simple') }
end

describe ec2(EC2Helper.GetIdFromName('packed')) do
  it { should exist }
  it { should be_running }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_simple') }
end

describe ec2(EC2Helper.GetIdFromName('dockerhost')) do
  it { should exist }
  it { should be_running }
  its(:image_id) { should eq 'ami-c22236a6' }
  its(:public_dns_name) { should eq '' }
  its(:instance_type) { should eq 't2.micro' }
  it { should have_security_group('devops_secg_simple') }
end

