class admintools::git_ssh (

  $github_over_https   = false,
  $known_hosts         = $admintools::known_hosts,
  $known_host_defaults = $admintools::known_host_defaults,

) {

  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {

      # always process known_hosts
      if ($known_hosts != {}) {
        create_resources(sshkey, $known_hosts, $known_host_defaults)
      }

      if ($github_over_https) {
        # indirect requests to github.com via ssh.github.com
        ssh_config { "admintools-github-over-https-hostname":
          ensure => present,
          host   => "github.com",
          key    => "Hostname",
          value  => "ssh.github.com",
        }
        ssh_config { "admintools-github-over-https-port":
          ensure => present,
          host   => "github.com",
          key    => "Port",
          value  => "443",
        }
      }
    }
    windows: {
      if ($github_over_https) {
        # make all SSH config changes to git's SSH; no ssh_config provider so have to hack file_line
        file_line { 'admintools-github-over-https-win1':
          path  => 'C://Program Files//Git//etc//ssh//ssh_config',
          line  => "Host github.com",
          match => '^Host github.com',
        } ->
        file_line { 'admintools-github-over-https-win2':
          path  => 'C://Program Files//Git//etc//ssh//ssh_config',
          line  => "    Hostname ssh.github.com",
          after => '^Host github.com',
        } ->
        file_line { 'admintools-github-over-https-win3':
          path  => 'C://Program Files//Git//etc//ssh//ssh_config',
          line  => "    Port 443",
          after => '^    Hostname ssh.github.com',
        }
      }
    }
  }

}
