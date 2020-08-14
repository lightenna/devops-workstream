
class admintools::git_ssh (

  $github_over_https = $admintools::github_over_https,
  $github_public_key = $admintools::github_public_key,

) {

  # indirect requests to github.com via ssh.github.com
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora, ubuntu, debian: {
      # accept Github's key
      sshkey { 'github.com':
        type   => 'ssh-rsa',
        key    => $github_public_key,
      }
      if ($github_over_https) {
        sshkey { 'ssh.github.com':
          type => 'ssh-rsa',
          key  => $github_public_key,
        }
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
