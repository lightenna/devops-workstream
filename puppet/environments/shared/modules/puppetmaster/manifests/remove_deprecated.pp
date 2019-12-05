
class puppetmaster::remove_deprecated (

) {

  # Remove retired configuration
  # systemd[1]: Starting puppetdb Service...
  # puppetdb[1035]: The [database] classname config option has been retired and will be ignored.
  # puppetdb[1035]: The [database] conn-keep-alive config option has been retired and will be ignored.
  # puppetdb[1035]: The [database] log-slow-statements config option has been retired and will be ignored.
  # puppetdb[1035]: The [database] subprotocol config option has been retired and will be ignored.
  # Started puppetdb Service.

  Ini_setting <| title == 'puppetdb_classname' |> {
    ensure => absent,
  }
  Ini_setting <| title == 'puppetdb_subprotocol' |> {
    ensure => absent,
  }
  Ini_setting <| title == 'puppetdb_log_slow_statements' |> {
    ensure => absent,
  }
  Ini_setting <| title == 'puppetdb_conn_keep_alive' |> {
    ensure => absent,
  }

}

