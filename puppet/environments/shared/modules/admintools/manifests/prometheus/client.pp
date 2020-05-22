
class admintools::prometheus::client (

  $client_fqdn = $::fqdn,
  $port = lookup('prometheus::node_exporter::scrape_port'),
  $exporters = [],
  $proxy_server = undef,

) {

  # monitoring agent
  include '::prometheus::node_exporter'

  if ($proxy_server != undef) {
    # set proxy on all archive resources
    Archive <| |> {
      proxy_server => $proxy_server,
    }
  }

  # optional monitoring agents
  if ('apache' in $exporters) {
    include '::prometheus::apache_exporter'
  }
  if ('collectd' in $exporters) {
    include '::prometheus::collectd_exporter'
  }
  if ('consul' in $exporters) {
    include '::prometheus::consul_exporter'
  }
  if ('elasticsearch' in $exporters) {
    include '::prometheus::elasticsearch_exporter'
  }
  if ('graphite' in $exporters) {
    include '::prometheus::graphite_exporter'
  }
  if ('haproxy' in $exporters) {
    include '::prometheus::haproxy_exporter'
  }
  if ('mongodb' in $exporters) {
    include '::prometheus::mongodb_exporter'
  }
  if ('mysqld' in $exporters) {
    include '::prometheus::mysqld_exporter'
  }
  if ('nginx' in $exporters) {
    include '::prometheus::nginx_vts_exporter'
  }
  if ('postfix' in $exporters) {
    include '::prometheus::postfix_exporter'
  }
  if ('postgres' in $exporters) {
    include '::prometheus::postgres_exporter'
  }
  if ('process' in $exporters) {
    include '::prometheus::process_exporter'
  }
  if ('rabbitmq' in $exporters) {
    include '::prometheus::rabbitmq_exporter'
  }
  if ('redis' in $exporters) {
    include '::prometheus::redis_exporter'
  }
  if ('snmp' in $exporters) {
    include '::prometheus::snmp_exporter'
  }
  if ('statsd' in $exporters) {
    include '::prometheus::statsd_exporter'
  }

  # currently unsupported exporters
  # include '::prometheus::beanstalkd_exporter'
  # include '::prometheus::bird_exporter'
  # include '::prometheus::blackbox_exporter'
  # include '::prometheus::mesos_exporter'
  # include '::prometheus::varnish_exporter'

  # register with MOTD
  if defined (Class['domotd']) {
    @domotd::register { "Prometheus(${port})" : }
  }

}
