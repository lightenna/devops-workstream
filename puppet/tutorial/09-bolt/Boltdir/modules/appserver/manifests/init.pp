class appserver (

  # class arguments

  $port = '80',
  # database connection details
  $database_name = 'staging-db',
  $database_user = 'admin',
  $database_pass = 'changeme',

  # end of class arguments
  # ----------------------
  # begin class

) {

  # top-level global variables (from facter), e.g.
  # ::hostname
  # ::fqdn

  # class-level variables (inherited from Hiera), e.g.
  # port
  # database_name, database_user, database_password

  # resource/low-level variables (defined in file resource), e.g.
  # service_name

  # create a file from a template
  file { '/tmp/configuration.xml':
    ensure => 'present',
    content => epp('appserver/configuration.xml.epp', {
      'service_name' => "${::hostname}-appserver"
    }),
  }

}
