

define usertools::safe_repo (

  $user = 'git',
  $group = 'iac-data',
  $group_writeable = false,
  $path = '/srv/git/github.com',
  $repo_name = $title,
  $revision = 'master',
  $source,
  $mode = '0750',
  $seltype = 'git_content_t',
  $require_key = true,

) {

  # make sure target base path exists (shared by several repos)
  if !defined(File["${path}"]) {
    ensure_resource(usertools::safe_directory, "${path}", {
      user  => "${user}",
      group => 'root',
      mode  => '0644',
    })
  }

  # create managed resource for repo directory itself
  ensure_resource(usertools::safe_directory, "${path}/${repo_name}", {
    user => "${user}",
    group => "${group}",
    mode  => '0640',
  })

  vcsrepo { "usertools-safe_repo-fetch-${title}":
    path => "${path}/${repo_name}",
    ensure => present,
    provider => git,
    source => $source,
    revision => $revision,
    # use SSH key in /home/git/.ssh/
    user => "${user}",
    # set ownership of working copy
    owner => $user,
    group => $group,
    require => [File["${path}"], File["${path}/${repo_name}"]],
  }

  if ($require_key) {
    Vcsrepo <| title == "usertools-safe_repo-fetch-${title}" |> {
      require => [File["${path}"], File["/home/${user}/.ssh/id_rsa"]],
    }
  }

  # hack to secure permissions, as currently no `mode` parameter for vcsrepo
  exec { "usertools-safe_repo-secureperms-${title}":
    path => '/bin:/usr/bin',
    command => "chmod -R o-rwx ${path}/${repo_name}",
    require => [Vcsrepo["usertools-safe_repo-fetch-${title}"]],
  }

  if (str2bool($::selinux)) {
    selinux::fcontext { "usertools-safe_repo-default-context-${title}" :
      seltype => "${seltype}",
      pathspec => "${path}/${repo_name}(/.*)?",
    }
  }

  if ($group_writeable) {
    # try to avoid this, because group-writeable tends to mean an exposed (web) service can write
    exec { "usertools-safe_repo-writeperms-${title}":
      path => '/bin:/usr/bin',
      command => "chmod -R g+w ${path}/${repo_name}",
      require => [Vcsrepo["usertools-safe_repo-fetch-${title}"]],
    }
  }

}