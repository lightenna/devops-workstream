# test for non-ssh exec
unless defined? $test_execution_method
  require 'serverspec'
  $test_execution_method = 'exec'
  set :backend, :exec
end

# puppet
describe package('puppetserver') do
  it { should be_installed }
end
describe service('puppetserver') do
  it { should be_enabled }
  it { should be_running }
end
describe port(8140) do
  it { should be_listening }
end
describe package('puppetdb') do
  it { should be_installed }
end
describe service('puppetdb') do
  it { should be_enabled }
  it { should be_running }
end
describe port(8081) do
  it { should be_listening }
end
# disable this curl test because it requires root access to ssl/certs/private_keys
#describe command("curl \"https://#{host_inventory['fqdn']}:8081/metrics/v1/mbeans/java.lang:type=Memory\" \
#  --tlsv1 \
#  --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
#  --cert /etc/puppetlabs/puppet/ssl/certs/#{host_inventory['hostname']}*.pem \
#  --key /etc/puppetlabs/puppet/ssl/private_keys/#{host_inventory['hostname']}*.pem") do
#  its(:stdout) { should contain('"ObjectPendingFinalizationCount":0') }
#  its(:stdout) { should contain('"ObjectName":"java.lang:type=Memory"') }
#end


# puppetboard
describe package('httpd'), :if => os[:family] == 'redhat' do
  it { should be_installed }
end
describe service('httpd'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
end
describe port(18080) do
  it { should be_listening }
end

# base components
describe selinux do
  it { should be_enforcing }
end