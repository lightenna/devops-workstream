
class puppetmaster::puppetboard (

  $cert_directory_path = '/etc/pki/tls/certs',
  $key_directory_path = '/etc/pki/tls/private',
  $cert_name = 'puppetmaster.localdomain',
  $use_https = true,
  $certificate = undef,
  $key = undef,
  $ca_bundle = undef,
  $htpasswd_username = 'admin',
  $htpasswd_password = 'admLn**',
  $board_realm = 'Puppetboard',
  $web_user = 'apache',
  $web_group = 'www-data',
  $web_passpath = '/var/www/secure',
  $web_port = 443,

) {

  if defined(Class['domotd']) {
    # register external services ()
    @domotd::register { "Puppetboard(${web_port})" : }
  }

  # install pre-reqs if not already present
  include '::apache'
  include '::apache::mod::version'
  include '::apache::mod::wsgi'
  include '::python'

  # install puppetboard
  class { '::puppetboard':
    reports_count => 20,
    default_environment => '*',
    # doesn't like using symlinked python 3.6, I suspect because of the environment variables/path
    # virtualenv_version => '3',
    # lock to puppetboard 1.0.0 because 1.1.0 breaks virtualenv/parse module
    revision => 'v1.0.0',
    # disable manage_virtualenv to avoid Python class collision
    manage_virtualenv => false,
    # leave r10k to pull in git package
    manage_git => false,
  }

  if ($certificate != undef) {
    # write out the certs/keys
    webtools::write_cert { "${cert_name}":
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

}

