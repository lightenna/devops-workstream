
define harden::disable_user (
  $user_name = $title
) {
  exec { "harden-disable-user-${user_name}" :
    path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
    command => "usermod --shell /bin/false ${user_name}",
    onlyif => "id -u ${user_name}",
  }
}
