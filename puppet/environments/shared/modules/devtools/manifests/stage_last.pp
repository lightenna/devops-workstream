
class devtools::stage_last (

  $script_name = undef,
  $path = '/srv/selftest',
  # [0-9]+ does not work here, so use *
  $match = '^[0-9]* examples, 0 failures$',

) {

  if ($script_name != undef) {
    # run test
    devtools::run_ruby { 'devtools-test-run-rspec-testsuite' :
      command => "rspec ${path}/${script_name} | grep \"${match}\" > /dev/null 2>&1",
      onlyif  => "test -e ${path}/${script_name}",
    }
  }

}
