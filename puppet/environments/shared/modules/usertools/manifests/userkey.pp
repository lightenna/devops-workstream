
define usertools::userkey (

  $user,
  $group,
  $key_name = $title,
  $key_public = undef,
  $key_private = undef,
  $key_private_append = "\n",
  $key_email = undef,
  $home,
  $path = "${home}/.ssh/${key_name}",
  $ssh_add = false,

) {

  File {
    ensure => present,
    path => $path,
    owner => $user,
    group => $group,
    mode => '0600',
    require => File["${home}/.ssh"],
  }

  if ($key_public != undef) {
    file { "usertools-userkey-public-${user}-${title}":
      content => "ssh-rsa ${key_public} pubkey in ${path} ${key_email}",
    }
  }
  if ($key_private != undef) {
    file { "usertools-userkey-private-${user}-${title}":
      # optionally append string (e.g. mandatory new line) onto the end of private key files
      content => "${key_private}${key_private_append}",
    }
    # load key into pre-loaded agent
    if ($ssh_add) {
      usertools::bashaddition { "usertools-userkey-bash-sshadd-${user}-${title}":
        content => "\n# Load SSH key {$key_name}\nif [ -z \"\$SSH_AUTH_SOCK\" ] ; then eval `ssh-agent -s` ; ssh-add ${path} ; fi\n",
        target  => '.bash_profile',
        user    => $user,
        home    => $home,
        order   => '55',
        require => [File[$home], File[$path]],
      }
    }
  }

}
