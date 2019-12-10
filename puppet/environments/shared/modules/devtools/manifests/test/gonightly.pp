
class devtools::test::gonightly (

  $path,
  $test_script_name = 'run_test_suite.sh',
  $user = 'remtest',
  $group = 'remtest',
  $redirect = '> /dev/null',

) {

  # every morning at 6am UTC
  cron { 'devtools-test-go-nightly':
    # need to source bashrc to get environment variables (e.g. do_token)
    command => "bash -c 'source /home/${user}/.bashrc && ${path}/${test_script_name} 2>&1' ${redirect} 2>&1",
    user => "${user}",
    hour => 6,
    minute => 0,
  }

}
