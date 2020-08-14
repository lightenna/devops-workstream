define usertools::safe_directory (
  $path        = $title,
  $ensure      = 'directory',
  $user        = 'root',
  $group       = undef,
  $mode        = '0750',
  $seltype     = undef,
  $treatas     = 'existing',
  $permissions = undef,
  $inherit     = true,
) {
  # always set up default mode and group
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      $resolved_mode = $mode
      $resolved_group = $group ? {
        undef   => 'root',
        default => $group,
      }
    }
    windows: {
      # don't set mode on Windows, use ACL
      $resolved_mode = undef
      $resolved_group = $group ? {
        undef   => 'Administrators',
        default => $group,
      }
    }
  }
  # avoid making directories when we're trying to remove them
  if ($ensure != 'absent' and $treatas == 'existing') {
    case $operatingsystem {
      centos, redhat, oraclelinux, fedora, ubuntu, debian: {
        exec { "usertools-safedir-${title}":
          path    => '/bin:/usr/bin',
          command => "mkdir -p ${path}",
          unless  => "test -d ${path}",
        }
        # if system uses SELinux, set fcontext
        if (str2bool($::selinux) and ($seltype != undef)) {
          # apply SELinux context if applicable and set
          selinux::fcontext { "usertools-safedir-seltype-${title}":
            seltype  => "${seltype}",
            pathspec => "${path}(/.*)?",
          }->
          # then apply to files
          exec { "usertools-safedir-seltype-${title}":
            path => ['/bin','/sbin','/usr/bin','/usr/sbin'],
            command => "restorecon -R ${path}",
          }
        }
        # allow ACL shorthand
        $resolved_permissions = $permissions ? {
          undef       => undef,
          'writeable' => [
            "user::rwx",
            "group::rwx",
            "mask::rwx",
            "other::---",
            "default:user::rwx",
            "default:group::rwx",
            "default:mask::rwx",
            "default:other::---",
          ],
          default     => $permissions,
        }
        if ($resolved_permissions != undef) {
          # apply ACL to control
          posix_acl { "usertools-safedir-${title}":
            path       => "${path}",
            action     => "set",
            permission => $resolved_permissions,
            provider   => "posixacl",
            recursive  => true,
          }
        }
      }

      windows: {
        exec { "usertools-safedir-${title}":
          command  => "mkdir ${path}",
          provider => powershell,
        }
        # allow ACL shorthand
        $resolved_permissions = $permissions ? {
          undef      => undef,
          'standard' => [
            { identity => $resolved_group, rights => ['full'], },
            { identity => 'NT AUTHORITY\\SYSTEM', rights => ['full'], },
            { identity => $user, rights => ['full'], },
          ],
          default    => $permissions,
        }
        if ($resolved_permissions != undef) {
          # by default enable inheritance, purge 'protected' permissions
          if !defined(Acl["${path}"]) {
            acl { "usertools-safedir-acl-${path}":
              target                     => $path,
              purge                      => true,
              permissions                => $resolved_permissions,
              inherit_parent_permissions => $inherit,
            }
          }
        }
      }
    }
  }

  if !defined(File["${path}"]) {
    # create file resource to allow other resources to require it
    ensure_resource(file, "${path}", {
      ensure => $ensure,
      force  => true,
      owner  => $user,
      group  => $resolved_group,
      mode   => $resolved_mode,
    })
  }

}