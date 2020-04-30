define usertools::sshconfig (

  $host = $title,
  $user,
  $hostname,
  $target,
  $port = undef,
  $proxy_user = $user,
  $proxy_host = undef,
  $proxy_port = 22,

) {

  Ssh_config {
    ensure => present,
    host   => $host,
    target => $target,
  }

  ssh_config { "usertools-sshconfig-hostname-${user}-${host}":
    key   => "  Hostname",
    value => $hostname,
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

}
