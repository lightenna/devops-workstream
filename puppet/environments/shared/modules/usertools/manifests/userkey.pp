
define usertools::userkey (

  $user,
  $group,
  $home,
  $key_name = $title,
  $key_public = undef,
  $key_private = undef,
  $key_email = undef,

) {

  File {
    ensure => present,
    path => "${home}/.ssh/${key_name}",
    owner => $user,
    group => $group,
    mode => '0600',
    require => File["${home}/.ssh"],
  }

  if ($key_public != undef) {
    file { "usertools-userkey-public-${user}-${title}":
      content => "ssh-rsa ${key_public} pubkey in ${home}/.ssh/${key_name} ${key_email}",
    }
  }
  if ($key_private != undef) {
    file { "usertools-userkey-private-${user}-${title}":
      content => $key_private,
    }
  }

}
