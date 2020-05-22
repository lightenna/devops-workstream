class admintools::hosts (

  $target       = '/etc/hosts',
  $purge_hosts  = true,
  $host_entries = {},
  $host_entry_default = {},
  $enable_ipv4_localhost = true,
  $enable_ipv6_localhost = true,

) {

  Host {
    target => $target,
  }

  resources { 'host':
    purge => $purge_hosts,
  }

  # append standard hosts if not already defined
  $standard_hosts4 = $enable_ipv4_localhost ? { true => {
    'localhost' => {
      ip => '127.0.0.1',
      host_aliases => ['localhost.localdomain', 'localhost4', 'localhost4.localdomain4'],
    }
  }, default => {} }
  $standard_hosts6 = $enable_ipv6_localhost ? { true => {
    'localhost6.localdomain6' => {
      ip => '::1',
      host_aliases => ['localhost6'],
    }
  }, default => {} }

  # create resources in all cases to allow for standard hosts
  create_resources(host, $host_entries + $standard_hosts4 + $standard_hosts6, $host_entry_default)

}
