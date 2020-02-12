
class devtools::test (

  $path = '/srv/selftest',
  $script_name = undef,
  $standardised_remote_script_name = 'selftest.rb',
  $user = 'root',
  $group = 'root',
  $selftest_module_path = 'selftest',
  $add_to_puppet_group = undef,

) {

  if ($script_name != undef) {
    include 'devtools::languages::ruby'
    # install required gems for post-run testing
    devtools::run_ruby { 'devtools-test-install-gems':
      command => 'gem install rake serverspec',
      require => [Anchor['devtools-languages-ruby-ready']],
    }

    # ensure that the test filepath exists
    usertools::safe_directory { 'devtools-test-filepath':
      path => "${path}",
      user => "${user}",
      group => "${group}",
      mode => '0750',
    }

    # transfer test script, but standardise name
    file { 'devtools-test-script':
      path => "${path}/selftest.rb",
      source => "puppet:///modules/${selftest_module_path}/${script_name}",
      owner => "${user}",
      group => "${group}",
      mode => '0640',
      require => [File["${path}"]],
    }

    # execute the test at the end of the puppet run
    class { 'devtools::stage_last':
      path => "${path}",
      script_name => $standardised_remote_script_name,
      stage => 'last',
      require => [File['devtools-test-script'], Devtools::Run_ruby['devtools-test-install-gems']],
    }

    # open up access to puppet certs by adding to the puppet group
    if ($add_to_puppet_group != undef) {
      exec { "devtools-test-empower-${add_to_puppet_group}-user-for-puppet-tests":
        path    => '/usr/sbin',
        # confusingly add '$group' user to puppet group, e.g. vagrant group selftest execution
        command => "usermod -a -G puppet ${add_to_puppet_group}",
      }
      # if the group is defined, wait until it's been created before running the exec
      Group <| title == 'puppet' |> {
        before => [Exec["devtools-test-empower-${add_to_puppet_group}-user-for-puppet-tests"]],
      }
    }

  }

}
