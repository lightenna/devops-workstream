
class puppetmaster::control_repo (

  $service_user = 'puppet',
  $service_group = 'puppet',
  $path = '/srv/git/github.com',
  $repo_name = 'devops-workstream',
  $revision = 'master',
  $source = 'https://github.com/lightenna/devops-workstream.git',
  $require_key = false,
  $puppetfile_relative_path = 'puppet',
  $puppetfile_name = 'Puppetfile',
  $cache_dir_path = '/var/cache',
  $group_writeable = false,
  $update_cadence = undef,
  $manage_repo = true,
  $manage_r10k_puppetfile = true,
  $manage_r10k_puppetfile_install = false,

) {

  if ($manage_repo) {
    # install pre-reqs if not already present
    include '::git'

    usertools::safe_repo { 'puppetmaster-control_repo-fetch':
      user            => $service_user,
      group           => $service_group,
      path            => $path,
      repo_name       => $repo_name,
      revision        => $revision,
      source          => $source,
      group_writeable => $group_writeable,
      require_key     => $require_key,
      update_cadence  => $update_cadence,
      before          => [Anchor['puppetmaster-control_repo-r10k-ready']],
    }

    anchor { 'puppetmaster-control_repo-r10k-ready': }

    if ($manage_r10k_puppetfile) {
      # create r10k.yaml config file
      file { 'puppetmaster-control_repo-config-r10k':
        ensure  => 'present',
        path    => "${path}/${repo_name}/${puppetfile_relative_path}/r10k.yaml",
        content => epp('puppetmaster/r10k.yaml.epp', {
          'cachedir' => "${cache_dir_path}/r10k"
        }),
        require => [Usertools::Safe_repo['puppetmaster-control_repo-fetch']],
        before  => [Anchor['puppetmaster-control_repo-r10k-ready']],
      }

      # install r10k for module management
      class { '::r10k':
        before => [Anchor['puppetmaster-control_repo-r10k-ready']],
      }

      # make group writeable cache folder
      file { 'puppetmaster-control_repo-r10k-make-cachedir':
        ensure => 'directory',
        path   => "${cache_dir_path}/r10k",
        owner  => 'root',
        group  => $service_group,
        mode   => '0770',
        before => [Anchor['puppetmaster-control_repo-r10k-ready']],
      }

      if ($manage_r10k_puppetfile_install) {
        # install puppetfile if one exists in control repo, but wipe the cache afterwards
        exec { 'puppetmaster-control_repo-r10k-puppetfile-install':
          path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
          command => "r10k puppetfile install && rm -rf ${cache_dir_path}/r10k/*",
          user    => $service_user,
          group   => $service_group,
          cwd     => "${path}/${repo_name}/${puppetfile_relative_path}",
          onlyif  => "test -e ${path}/${repo_name}/${puppetfile_relative_path}/${puppetfile_name}",
          require => [Anchor['puppetmaster-control_repo-r10k-ready']],
          timeout => 20 * 60, # restrict run to max 20 minutes
        }
      }
    }
  }
}

