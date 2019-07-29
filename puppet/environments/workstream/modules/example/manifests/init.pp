class example (

  # class arguments

  $user = 'centos',
  $notifier_dir = '/etc/puppet/tmp',

  # end of class arguments
  # ----------------------
  # begin class

) {

  debug("This is some output from the 'example' module, visible only with -d or --debug.")

}