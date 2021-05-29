define usertools::safe_repo (

  $user             = 'git',
  $group            = 'iac-data',
  $group_writeable  = false,
  $path             = '/srv/git/github.com',
  $ensure           = 'present',
  $repo_name        = $title,
  $manage_repo      = $usertools::manage_repos,
  $revision         = 'master',
  $source,
  $mode             = '0640',
  $seltype          = 'git_content_t',
  $require_key      = true,
  $update_cadence   = undef,
  $files            = {},
  $file_defaults    = {},
  $symlinks         = {},
  $symlink_defaults = {},

) {

  # sometimes repos are shared into vagrant boxes, so manage_repo = false acts as a kill switch
  if ($manage_repo) {
    # make sure target base path exists (shared by several repos)
    if !defined(Usertools::Safe_directory["${path}"]) {
      ensure_resource(usertools::safe_directory, "${path}", {
        user  => $user,
        group => 'root',
        mode  => '0644',
      })
    }

    # create managed resource for repo directory itself
    if !defined(Usertools::Safe_directory["${path}/${repo_name}"]) {
      ensure_resource(usertools::safe_directory, "${path}/${repo_name}", {
        user   => $user,
        group  => $group,
        ensure => $ensure,
        mode   => $mode,
      })
    }

    if ($ensure == 'present') {
      vcsrepo { "usertools-safe_repo-fetch-${user}-${title}":
        path     => "${path}/${repo_name}",
        ensure   => present,
        provider => git,
        source   => $source,
        revision => $revision,
        # use SSH key in /home/git/.ssh/
        user     => $user,
        # set ownership of working copy
        owner    => $user,
        group    => $group,
        require  => [File["${path}"], File["${path}/${repo_name}"]],
      }

      if ($require_key) {
        Vcsrepo <| title == "usertools-safe_repo-fetch-${user}-${title}" |> {
          require => [File["${path}"], File["/home/${user}/.ssh/id_rsa"]],
        }
      }

      # hack to secure permissions, as currently no `mode` parameter for vcsrepo
      exec { "usertools-safe_repo-secureperms-${user}-${title}":
        path    => '/bin:/usr/bin',
        command => "chmod -R o-rwx ${path}/${repo_name}",
        require => [Vcsrepo["usertools-safe_repo-fetch-${user}-${title}"]],
      }

      if (str2bool($::selinux)) {
        selinux::fcontext { "usertools-safe_repo-default-context-${user}-${title}":
          seltype  => "${seltype}",
          pathspec => "${path}/${repo_name}(/.*)?",
        }
      }

      if ($group_writeable) {
        # try to avoid this, because group-writeable tends to mean an exposed (web) service can write
        exec { "usertools-safe_repo-writeperms-${user}-${title}":
          path    => '/bin:/usr/bin',
          command => "chmod -R g+w ${path}/${repo_name}",
          require => [Vcsrepo["usertools-safe_repo-fetch-${user}-${title}"]],
        }
      }
    }

    # update repo using cron task if set
    if ($update_cadence != undef) {
      ensure_resource(cron, "usertools-safe_repo-cronupdate-${user}-${title}", {
        ensure  => $ensure,
        command =>
        "/usr/bin/git --git-dir=${path}/${repo_name}/.git --work-tree=${path}/${repo_name} pull > /dev/null 2>&1",
        user    => $user,
        require => [Vcsrepo["usertools-safe_repo-fetch-${user}-${title}"]],
        hour    => 0,
        minute  => 0,
      } + $update_cadence)
    }

    # create files if set
    if ($files != {}) {
      create_resources(file, $files, {
        owner   => $user,
        group   => $group,
        ensure  => $ensure,
        mode    => $mode,
        # by default, create files only after the repo is checked out
        require => $ensure ? {
          "present" => [Vcsrepo["usertools-safe_repo-fetch-${user}-${title}"]],
          default   => [],
        },
      } + $file_defaults)
    }

    if ($symlinks != {}) {
      create_resources(usertools::safe_symlink, $symlinks, {
        # by default, symlinks created relative to the repo base
        link_base => "${path}/${repo_name}/",
        user      => $user,
        group     => $group,
        ensure    => $ensure,
        require   => $ensure ? {
          "present" => [Vcsrepo["usertools-safe_repo-fetch-${user}-${title}"]],
          default   => [],
        },
      } + $symlink_defaults)
    }

  }

}