#
# Linux/Windows compatible
# Windows defaults set at call time (from init.pp) because cannot inherit in defined type
#
define usertools::write_keypair (

  $user = $title,
  $group = $title,
  $mode = '0600',
  $path = '/srv/keys',
  $ensure = 'present',
  $key_private = undef,
  $key_private_name = 'private_key.pkcs7.pem',
  $key_public = undef,
  $key_public_name = 'public_key.pkcs7.pem',

) {

  ensure_resource(usertools::safe_directory, "usertools-write_keypair-ensdir-${title}", {
    path    => $path,
    mode    => $mode,
    user    => $user,
    group   => $group,
  })

  File {
    ensure => $ensure,
    owner => $user,
    group => $group,
    mode => $mode,
  }

  if ($key_private != undef) {
    file { "usertools-write_keypair-private-${title}":
      path    => "${path}/${key_private_name}",
      content => $key_private,
      require => File["${path}"],
    }
  }

  if ($key_public != undef) {
    file { "usertools-write_keypair-public-${title}":
      path    => "${path}/${key_public_name}",
      content => $key_public,
      require => File["${path}"],
    }
  }

}

