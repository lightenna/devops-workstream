
class harden::stage_last (

  $puppetmless_path = '/etc/puppetlabs/puppetmless',
  $remove_rootlike = true,

) {

  # remove default OS users, after may have been used for provisioning
  case $operatingsystem {
    centos, redhat, fedora: {
      harden::remove_user { 'centos' : }
    }
    ubuntu, debian: {
      harden::remove_user { 'ubuntu' : }
    }
  }

  if ($remove_rootlike) {
    # remove provisioning user, if neither root nor default OS user used for provisioning
    harden::remove_user { 'rootlike': }
  }

  # delete any manifests transferred as part of a masterless puppet run, but leave folder for re-sync
  exec { 'harden-remove-puppetmless':
    path => '/usr/bin',
    command => "rm -rf ${puppetmless_path}/*",
    onlyif => "test -e ${puppetmless_path}/Puppetfile",
  }

}
