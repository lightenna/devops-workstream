class example (

  # class arguments

  $user = 'centos',
  $notifier_dir = '/etc/puppet/tmp',

  # end of class arguments
  # ----------------------
  # begin class

) {

  notify { 'example-notify':
    message => "This is some output from the 'example' module.",
  }

}