class example (

  # class arguments

  $user,

  # end of class arguments
  # ----------------------
  # begin class

) {

  # notice how the double quotes allow for variable substitution
  debug("The value of the variable \$user is ${user}, double-quoted")

  # single quoted strings are literal
  debug('Single quoted strings are interpreted literally (no substitution).  The value of the variable \$user is ${user}')

}