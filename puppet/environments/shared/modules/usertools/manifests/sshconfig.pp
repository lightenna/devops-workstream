define usertools::sshconfig (

  $host = $title,
  $user,
  $ensure = 'present',
  $hostname = undef,
  $username = undef,
  $target,
  $port = undef,
  $proxy_user = $user,
  $proxy_host = undef,
  $proxy_port = 22,
  $identity_file = undef,
  $local_forward = undef,
  $remote_forward = undef,
  $additional_lines = {},

) {

  Ssh_config {
    ensure => $ensure,
    host   => $host,
    target => $target,
  }

  if ($username != undef) {
    ssh_config { "usertools-sshconfig-username-${user}-${host}":
      key   => "  User",
      value => $username,
    }
  }

  if ($hostname != undef) {
    ssh_config { "usertools-sshconfig-hostname-${user}-${host}":
      key   => "  Hostname",
      value => $hostname,
    }
  }

  if ($port != undef) {
    ssh_config { "usertools-sshconfig-port-${user}-${host}":
      key   => "  Port",
      value => "${port}",
    }
  }

  if ($proxy_host != undef) {
    ssh_config { "usertools-sshconfig-proxy-${user}-${host}":
      key   => "  ProxyCommand",
      value => "ssh -p ${proxy_port} -o StrictHostKeyChecking=no -W %h:%p ${proxy_user}@${proxy_host}",
    }
  }

  if ($identity_file != undef) {
    ssh_config { "usertools-sshconfig-identityfile-${user}-${host}":
      key   => "  IdentityFile",
      value => "${identity_file}",
    }
  }

  if ($local_forward != undef) {
    ssh_config { "usertools-sshconfig-localforward-${user}-${host}":
      key   => "  LocalForward",
      value => "${local_forward}",
    }
  }

  if ($remote_forward != undef) {
    ssh_config { "usertools-sshconfig-remoteforward-${user}-${host}":
      key   => "  RemoteForward",
      value => "${remote_forward}",
    }
  }

  if ($additional_lines != {}) {
    $additional_lines.each |$key, $value| {
      ssh_config { "usertools-sshconfig-additionals-${user}-${host}-${key}":
        key   => "${key}",
        value => "${value}",
      }
    }
  }

}
