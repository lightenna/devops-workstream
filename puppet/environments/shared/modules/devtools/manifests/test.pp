
class devtools::test (

  $path = '/srv/selftest',
  $script_name = undef,
  $standardised_remote_script_name = 'selftest.rb',
  $user = 'root',
  $group = 'root',
  $selftest_module_path = 'selftest',

) {

  if ($script_name != undef) {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora: {
        # install SCL (non-exclusively)
        include '::scl'
        # use up-to-date Ruby globally
        ensure_resource(scl::collection, 'rh-ruby25', {
          enable => true,
          before => Anchor['devtools-languages-ruby-ready'],
        })
      }
      ubuntu, debian: {
      }
    }
    ensure_resource(anchor,'devtools-languages-ruby-ready',{})

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
      mode => '0700',
    }

    # transfer test script, but standardise name
    file { 'devtools-test-script':
      path => "${path}/selftest.rb",
      source => "puppet:///modules/${selftest_module_path}/${script_name}",
      owner => "${user}",
      group => "${group}",
      mode => '0600',
      require => [File["${path}"]],
    }

    # execute the test at the end of the puppet run
    class { 'devtools::stage_last':
      path => "${path}",
      script_name => $standardised_remote_script_name,
      stage => 'last',
      require => [File['devtools-test-script'], Devtools::Run_ruby['devtools-test-install-gems']],
    }
  }

}