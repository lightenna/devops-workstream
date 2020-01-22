
class puppetmaster::puppetboard (

  $cert_directory_path = '/etc/pki/tls/certs',
  $key_directory_path = '/etc/pki/tls/private',
  $cert_name = 'localhost',
  $use_https = true,
  $certificate = undef,
  $key = undef,
  $ca_bundle = undef,
  $htpasswd_username = 'admin',
  $htpasswd_password = 'admLn**',
  $board_realm = 'Puppetboard',
  $board_offline = true,
  $web_user = 'apache',
  $web_group = 'apache',
  $web_passpath = '/var/www/secure',
  $web_port = 443,

) {

  anchor { 'puppetmaster-puppetboard-containment-begin' : }

  if defined(Class['domotd']) {
    # register external services ()
    @domotd::register { "Puppetboard(${web_port})" : }
  }

  # install pre-reqs if not already present
  include '::apache'
  include '::apache::mod::version'
  include '::apache::mod::wsgi'
  include '::python'
  include '::git'

  # install puppetboard
  class { '::puppetboard':
    reports_count => 20,
    default_environment => '*',
    # doesn't like using symlinked python 3.6, I suspect because of the environment variables/path
    # virtualenv_version => '3',
    # lock to puppetboard 1.0.0 because 1.1.0 breaks virtualenv/parse module
    revision => 'v1.0.0',
    # disable manage_virtualenv to avoid Python class collision; requires python::virtualenv: "present"
    manage_virtualenv => false,
    # leave r10k to pull in git package
    manage_git => false,
    # use in offline mode to avoid CDN call-outs
    offline_mode => $board_offline,
    # contain
    require => [Anchor['puppetmaster-puppetboard-containment-begin']],
    before => [Anchor['puppetmaster-puppetboard-containment-complete']],
  }

  # perform checkout using named user
  Vcsrepo <| title == '/srv/puppetboard/puppetboard' |> {
    user => $::puppetboard::user,
    # fix missing dep on directory for vcsrepo to checkout into
    require => [User[$::puppetboard::user],File[$::puppetboard::basedir]],
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

  if ($use_https) {
    # expose Puppetboard over HTTPS on target port
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
  usertools::safe_directory { 'puppetmaster-board-httpd-secure-dir' :
    path => $web_passpath,
    group => $web_group,
  }
  ::Apache::Vhost <| title == "${cert_name}" |> {
    directories => [
      {
        path => '/',
        auth_type => 'Basic',
        auth_name => "${board_realm}",
        auth_user_file => "${web_passpath}/.htpasswd",
        auth_require => "valid-user",
      }
    ],
    # require => [Usertools::Safe_directory['puppetmaster-board-httpd-secure-dir']],
    require => [File[$web_passpath]],
  }
  $template = @("PUPBRDHTPASS"/L)
    <%= @htpasswd_username %>:<%= scope.call_function('apache_pw_hash', [@htpasswd_password]) %>
    | PUPBRDHTPASS
  file { 'puppetmaster-board-htpasswd' :
    path => "${web_passpath}/.htpasswd",
    owner => 'root',
    group => $web_group,
    mode => '0640',
    require => [File[$web_passpath]],
    content => inline_template($template),
  }

  # use anchor pattern to ensure containment of selected resources
  anchor { 'puppetmaster-puppetboard-containment-complete' : }
}

