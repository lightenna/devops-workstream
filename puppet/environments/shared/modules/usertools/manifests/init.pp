
class usertools (

  # class arguments
  # ---------------
  # setup defaults

  $user = undef,
  $users = {},
  $user_defaults = {},

  # end of class arguments
  # ----------------------
  # begin class

) {

  if ($user != undef) {
    usertools::user { 'usertools-user-default-user' :
      user => $user,
    }
  }

  # create multiple users if details passed in hash
  if ($users != {}) {
    create_resources(usertools::user, $users, $user_defaults)
  }

}
