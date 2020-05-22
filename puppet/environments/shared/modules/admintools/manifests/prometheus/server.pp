class admintools::prometheus::server (

  $port                   = lookup('tcp::ports::prometheus_server', undef, undef, 9090),
  $port_https             = lookup('tcp::ports::prometheus_server_ext', undef, undef, 19090),
  $proxy_server           = undef,

  # optional proxying via Apache
  $install_vhosts         = false,
  $external_service_https = true,
  $servername             = $::fqdn,
  $aliases                = [],
  $cert_directory_path    = '/etc/pki/tls/certs',
  $key_directory_path     = '/etc/pki/tls/private',
  $cert_name              = $::fqdn,
  $default_html_docroot   = '/var/www/html',
  $user                   = 'git',
  $group                  = 'www-data',

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
    @domotd::register { "Prometheus-server[${port}]": }
  }

  if ($install_vhosts) {
    # include mod_proxy for ProxyPass and ProxyPassReverse directives
    include "apache::mod::proxy"
    include "apache::mod::proxy_http"

    # register in MOTD
    if defined(Class['domotd']) {
      @domotd::register { "Apache(${port_https})": }
    }

    # all external requests are proxied (to app/microservices) and require basic auth
    apache::vhost { "admintools-prometheus-server-${port_https}-${port}-vhost":
      port            => $port_https,
      servername      => $servername,
      serveraliases   => $aliases,
      docroot         => $default_html_docroot,
      docroot_owner   => $user,
      docroot_group   => $group,
      proxy_requests  => false, # Off
      require         => Class['::apache'], # don't try to create an vhosts until Apache is installed (need /var/www)
      custom_fragment => @("END")
        ProxyPass        "/"  "http://localhost:${port}/"
        ProxyPassReverse "/"  "http://localhost:${port}/"
      | END
    }

    # by default, all external requests are made over HTTPS
    if ($external_service_https) {
      ::Apache::Vhost <| title == "admintools-prometheus-server-${port_https}-${port}-vhost" |> {
        ssl               => true,
        ssl_cert          => "${cert_directory_path}/${cert_name}.crt",
        ssl_ca            => "${cert_directory_path}/${cert_name}.ca-bundle",
        ssl_key           => "${key_directory_path}/${cert_name}.key",
        # verify client required in order to include ssl_ca
        ssl_verify_client => 'none',
      }
    }

    if (($port != 80) and ($port_https != 443)) {
      if (str2bool($::selinux)) {
        ensure_resource(selinux::port, "admintools-prometheus-server-${port_https}-port", {
          seltype  => 'http_port_t',
          port     => $port_https,
          protocol => 'tcp',
          notify   => Class['::apache::service'],
        })
        ensure_resource(selinux::port, "admintools-prometheus-server-${port}-port", {
          seltype  => 'http_port_t',
          port     => $port,
          protocol => 'tcp',
          notify   => Class['::apache::service'],
        })
      }
    }
  }

}
