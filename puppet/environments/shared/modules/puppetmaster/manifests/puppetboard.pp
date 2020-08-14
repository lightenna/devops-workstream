class puppetmaster::puppetboard (
  $cert_directory_path  = '/etc/pki/tls/certs',
  $key_directory_path   = '/etc/pki/tls/private',
  $cert_name            = 'localhost',
  $use_https            = true,
  $certificate          = undef,
  $key                  = undef,
  $ca_bundle            = undef,
  $htpasswd_username    = 'admin',
  $htpasswd_password    = undef,
  $htpasswd_realm       = 'Puppetboard',
  $htpasswd_leafname    = '.htpasswd-pupbrd',
  $htpasswd_path         = '/var/www/secure',
  $board_offline        = true,
  $board_git_revision   = 'v2.1.2', # was 'v2.1.2' on 6/5/2020
  $board_python_version = '3',
  $board_reports_count  = 20,
  $board_default_env    = '*',
  $web_user             = 'apache',
  $web_group            = 'apache',
  $web_port             = 443,

) {

  anchor { 'puppetmaster-puppetboard-containment-begin': }

  if defined(Class['domotd']) {
    # register external services ()
    @domotd::register { "Puppetboard(${web_port})": }
  }

  # install pre-reqs if not already present
  include '::apache'
  include '::apache::mod::version'
  include '::apache::mod::wsgi'
  include '::python'
  include '::git'

  # requires upgraded apache for mod_wsgi, for python 3
  # + apache::version::scl_httpd_version: "2.4"
  # if you set scl_httpd_version you also have to set scl_php_version
  # + apache::version::scl_php_version: "7.2"
  # updated apache also required upgraded mod_wsgi
  # + apache::mod::wsgi::package_name: "rh-python36-mod_wsgi"
  # + apache::mod::wsgi::mod_path: "/opt/rh/httpd24/root/etc/httpd/modules/mod_rh-python36-wsgi.so"

  # install puppetboard
  class { '::puppetboard':
    reports_count       => $board_reports_count,
    default_environment => $board_default_env,
    # configure puppetboard to use specific version of python
    virtualenv_version  => $board_python_version,
    # checkout a tagged version of puppetboard
    revision            => $board_git_revision,
    # disable manage_virtualenv to avoid Python class collision; requires python::virtualenv: "present"
    manage_virtualenv   => false,
    # leave r10k to pull in git package
    manage_git          => false,
    # use in offline mode to avoid CDN call-outs
    offline_mode        => $board_offline,
    # contain
    require             => [Anchor['puppetmaster-puppetboard-containment-begin']],
    before              => [Anchor['puppetmaster-puppetboard-containment-complete']],
  }

  # perform checkout using named user
  Vcsrepo <| title == '/srv/puppetboard/puppetboard' |> {
    user    => $::puppetboard::user,
    # fix missing dep on directory for vcsrepo to checkout into
    require => [User[$::puppetboard::user], File[$::puppetboard::basedir]],
  }

  # modify puppetboard wsgi.py conf
  $basedir = $::puppetboard::basedir
  File <| title == "${::puppetboard::basedir}/puppetboard/wsgi.py" |> {
    # fix non-Python 3 code (execfile)
    content => template('puppetmaster/wsgi.py.erb'),
  }

  if ($certificate != undef) {
    # write out the certs/keys
    puppetmaster::write_cert { "${cert_name}":
      cert_directory_path => $cert_directory_path,
      key_directory_path  => $key_directory_path,
      key                 => $key,
      certificate         => $certificate,
      ca_bundle           => $ca_bundle,
    }
  }

  # expose Puppetboard over HTTPS on target port
  if ($use_https) {
    $filename_certificate = "${cert_directory_path}/${cert_name}.crt"
    $filename_key = "${key_directory_path}/${cert_name}.key"
    class { 'puppetboard::apache::vhost':
      vhost_name => "${cert_name}",
      ssl        => true,
      ssl_cert   => $filename_certificate,
      ssl_key    => $filename_key,
      port       => $web_port,
    }
  } else {
    class { 'puppetboard::apache::vhost':
      vhost_name => "${cert_name}",
      ssl        => false,
      port       => $web_port,
    }
  }

  if (str2bool($::selinux)) {
    # open non-standard ports for SELinux, if in use
    if ($web_port != 443) {
      selinux::port { 'puppetmaster-board-seport':
        seltype  => 'http_port_t',
        port     => $web_port,
        protocol => 'tcp',
      }
    }
  }

  # modify vhost to require a password
  if ($htpasswd_password != undef) {
    usertools::safe_directory { 'puppetmaster-board-httpd-secure-dir':
      path  => $htpasswd_path,
      group => $web_group,
    }
    ::Apache::Vhost <| title == "${cert_name}" |> {
      directories => [
        {
          path            => '/',
          auth_type       => 'Basic',
          auth_name       => "${htpasswd_realm}",
          auth_user_file  => "${htpasswd_path}/${htpasswd_leafname}",
          # deny by default, then allow IP (localhost) or valid user
          auth_require    => "all denied",
          custom_fragment => '
        <RequireAny>
          Require ip 127.0.0.1
          Require valid-user
        </RequireAny>
        ',
          # auth_require => "valid-user",
        }
      ],
      # require => [Usertools::Safe_directory['puppetmaster-board-httpd-secure-dir']],
      require     => [File[$htpasswd_path]],
    }
    $template = @("PUPBRDHTPASS"/L)
    <%= @htpasswd_username %>:<%= scope.call_function('apache_pw_hash', [@htpasswd_password]) %>
    | PUPBRDHTPASS
    file { 'puppetmaster-board-htpasswd':
      path    => "${htpasswd_path}/${htpasswd_leafname}",
      owner   => 'root',
      group   => $web_group,
      mode    => '0640',
      require => [File[$htpasswd_path]],
      content => inline_template($template),
    }
    # @todo minor tidy-up only: remove after a few versions > 0.2.2
    file { 'puppetmaster-board-htpasswd-cleanupold':
      path   => "${htpasswd_path}/.htpasswd",
      ensure => 'absent',
    }
  }

  # use anchor pattern to ensure containment of selected resources
  anchor { 'puppetmaster-puppetboard-containment-complete': }
}

