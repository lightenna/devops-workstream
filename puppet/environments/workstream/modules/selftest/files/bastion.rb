# test for non-ssh exec
unless defined? $test_execution_method
  require 'serverspec'
  $test_execution_method = 'exec'
  set :backend, :exec
end

# base components
describe port(15022) do
  it { should be_listening }
end
describe selinux do
  it { should be_enforcing }
end
describe yumrepo('epel') do
  it { should be_enabled }
end

# users
describe user('git') do
  it { should belong_to_primary_group 'iac-data' }
end
