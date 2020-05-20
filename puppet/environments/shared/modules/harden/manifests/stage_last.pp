
class harden::stage_last (

  $puppetmless_path = '/etc/puppetlabs/puppetmless',
  $remove_opc = true,
  $remove_rootlike = true,
  $remove_deprecated = true,
  $remove_osdefaultuser = true,
  $disable_osdefaultuser = false,

) {

  if ($remove_osdefaultuser) {
    # remove default OS users, after may have been used for provisioning
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora: {
        harden::remove_user { 'centos': }
      }
      ubuntu, debian: {
        harden::remove_user { 'ubuntu': }
      }
    }
  } else {
    if ($disable_osdefaultuser) {
      # disable default OS users
      case $operatingsystem {
        centos, redhat, oraclelinux, fedora: {
          harden::disable_user { 'centos': }
        }
        ubuntu, debian: {
          harden::disable_user { 'ubuntu': }
        }
      }
    }
  }

  if ($remove_rootlike) {
    # remove provisioning user, if neither root nor default OS user used for provisioning
    harden::remove_user { 'rootlike': }
  }

  if ($remove_opc) {
    harden::remove_user { 'opc': }
  }

  if ($remove_deprecated) {
    harden::remove_user { 'lightenn': }
  }

  # delete any manifests transferred as part of a masterless puppet run, but leave folder for re-sync
  exec { 'harden-remove-puppetmless':
    path => ['/bin', '/usr/bin'],
    command => "rm -rf ${puppetmless_path}/*",
    onlyif => "test -e ${puppetmless_path}/Puppetfile",
  }
  exec { 'harden-remove-tmp-hiera':
    path => ['/bin', '/usr/bin'],
    command => "rm -rf /tmp/hiera_packer/",
    onlyif => "test -e /tmp/hiera_packer/",
  }

}
