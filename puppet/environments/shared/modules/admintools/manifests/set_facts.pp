define admintools::set_facts (

  $path     = undef,
  $leafname = 'puppet-facts.yaml',
  $user     = undef,
  $group    = undef,

  $role     = undef,
  $environ  = undef,
  $cluster  = undef,

) {

  # use path if set, otherwise fall back to default path
  case $::operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      $path_default = '/etc/puppetlabs/facter/facts.d'
      $user_default = 'root'
      $group_default = 'root'
    }
    windows: {
      $path_default = 'C:/ProgramData/PuppetLabs/facter/facts.d'
      $user_default = 'NT AUTHORITY\SYSTEM'
      $group_default = 'Administrators'
    }
  }
  $path_resolved = $path ? {
    undef => $path_default,
    default => $path,
  }
  $user_resolved = $user ? {
    undef => $user_default,
    default => $user,
  }
  $group_resolved = $group ? {
    undef => $group_default,
    default => $group,
  }

  # one directory resource (between all defined types) for path
  ensure_resource(usertools::safe_directory, "${path_resolved}", {
    user  => $user_resolved,
    group => $group_resolved,
  })

  # set up sensible defaults
  $role_resolved = $role ? { undef => "", default => $role }
  $environ_resolved = $environ ? { undef => "", default => $environ }
  $cluster_resolved = $cluster ? { undef => "", default => $cluster }

  if ($role != undef or $environ != undef or $cluster != undef) {
    # write facts out to target file
    file { "admintools-facts-${title}":
      path    => "${path_resolved}/${leafname}",
      require => [File["${path_resolved}"]],
      owner   => $user_resolved,
      group   => $group_resolved,
      content => @("END")
        # External facts file, created by Puppet for non-Terraformed machines
        ---
        role: "${role_resolved}"
        environ: "${environ_resolved}"
        cluster: "${cluster_resolved}"
        | END
    }
  }

  # deprecate old facts files
  ensure_resource(file, "admintools-facts-remove-old-ext", {
    ensure => 'absent',
    path => "${path_resolved}/ext-facts.yaml",
  })
  ensure_resource(file, "admintools-facts-remove-old-vg-ext", {
    ensure => 'absent',
    path => "${path_resolved}/vg-ext-facts.yaml",
  })

}
