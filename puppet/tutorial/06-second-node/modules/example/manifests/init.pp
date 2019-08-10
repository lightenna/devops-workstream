class example (

  # class arguments

  $user = 'centos',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # notice how the double quotes allow for variable substitution
  debug("The value of the variable \$user is ${user} on ${::hostname}")

}