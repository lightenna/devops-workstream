define admintools::set_facts (

  $path     = '/etc/puppetlabs/facter/facts.d',
  $leafname = 'puppet-facts.yaml',
  $user     = 'root',
  $group    = 'root',

  $role     = undef,
  $environ  = undef,
  $cluster  = undef,

) {

  # one directory resource (between all defined types) for path
  ensure_resource(usertools::safe_directory, "${path}", {})

  # set up sensible defaults
  $role_resolved = $role ? { undef => "", default => $role }
  $environ_resolved = $environ ? { undef => "", default => $environ }
  $cluster_resolved = $cluster ? { undef => "", default => $cluster }

  if ($role != undef or $environ != undef or $cluster != undef) {
    # write facts out to target file
    file { "admintools-facts-${title}":
      path    => "${path}/${leafname}",
      require => [File[$path]],
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
    path => "${path}/ext-facts.yaml",
  })
  ensure_resource(file, "admintools-facts-remove-old-vg-ext", {
    ensure => 'absent',
    path => "${path}/vg-ext-facts.yaml",
  })

}
