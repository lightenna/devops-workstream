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
        # External facts file, created by Puppet
        ---
        role: "${role_resolved}"
        environ: "${environ_resolved}"
        cluster: "${cluster_resolved}"
        | END
    }

    case $::operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        # write out facts as globally-accessible environment variables
        file { "admintools-facts-envvars-${title}":
          path    => "/etc/profile.d/setfacts-${title}.sh",
          owner   => $user_resolved,
          group   => $group_resolved,
          content => @("END")
            # Export facts as environment variables, created by Puppet
            export FACTS_ROLE="${role_resolved}"
            export FACTS_ENVIRON="${environ_resolved}"
            export FACTS_CLUSTER="${cluster_resolved}"
            | END
        }
      }
      windows: {
        # create globally-accessible (system) environment variables
        windows_env { "admintools-facts-envvars-${title}-role":
          mergemode => 'clobber',
          variable  => 'FACTS_ROLE',
          value     => $role_resolved,
        }
        windows_env { "admintools-facts-envvars-${title}-environ":
          mergemode => 'clobber',
          variable  => 'FACTS_ENVIRON',
          value     => $environ_resolved,
        }
        windows_env { "admintools-facts-envvars-${title}-cluster":
          mergemode => 'clobber',
          variable  => 'FACTS_CLUSTER',
          value     => $cluster_resolved,
        }
      }
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
