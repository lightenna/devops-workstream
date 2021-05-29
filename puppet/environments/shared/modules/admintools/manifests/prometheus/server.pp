class admintools::prometheus::server (

  $service_port           = lookup('tcp::ports::prometheus_server', undef, undef, 9090),
  $apache_port            = lookup('tcp::ports::prometheus_server_ext', undef, undef, 19090),
  $proxy_server           = undef,

  # optional proxying via Apache
  $install_vhosts         = false,
  $servername             = $::fqdn,
  $aliases                = [],
  $cert_name              = $::fqdn,
  $user                   = 'apache',
  $group                  = 'www-data',

  # optional password if Apache proxied
  $htpasswd_username      = 'admin',
  $htpasswd_password      = undef,
  $htpasswd_realm         = 'Prometheus',
  $htpasswd_leafname      = '.htpasswd-prom',
  $htpasswd_path          = '/var/www/secure',
  $htpasswd_credentials   = {},

) {

  # monitoring server
  include '::prometheus::server'
  include '::prometheus::alertmanager'

  if ($proxy_server != undef) {
    Archive <| title == "/tmp/prometheus-${prometheus::server::version}.${prometheus::server::download_extension}" |> {
      proxy_server => $proxy_server,
    }
  }

  # register with MOTD
  if defined(Class['domotd']) {
    @domotd::register { "Prometheus-server[${service_port}]": }
  }

  if ($install_vhosts) {
    webtools::proxyport { "admintools-prometheus-server-proxyport-${apache_port}":
      service_port           => $service_port,
      apache_port            => $apache_port,
      servername             => $servername,
      aliases                => $aliases,
      cert_name              => $cert_name,
      user                   => $user,
      group                  => $group,
    }
    if ($htpasswd_password != undef) or ($htpasswd_credentials != {}) {
      Webtools::Proxyport <| title == "admintools-prometheus-server-proxyport-${apache_port}" |> {
        htpasswd_username      => $htpasswd_username,
        htpasswd_password      => $htpasswd_password,
        htpasswd_realm         => $htpasswd_realm,
        htpasswd_leafname      => $htpasswd_leafname,
        htpasswd_path          => $htpasswd_path,
        htpasswd_credentials   => $htpasswd_credentials,
      }
    }
  }

}
