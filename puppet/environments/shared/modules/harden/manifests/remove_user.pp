
define harden::remove_user (
  $user_name = $title
) {
  user { "${user_name}" :
    ensure => 'absent',
  }
  file { "/home/${user_name}" :
    ensure => 'absent',
    force  => true,
  }
}
