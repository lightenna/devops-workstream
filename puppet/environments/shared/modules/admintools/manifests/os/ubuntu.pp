class admintools::os::ubuntu (

  $user = 'root',
  $group = 'root',

) {

  # write out location of SSL certificates
  file { "admintools-os-ubuntu-envvars-certs":
    path    => "/etc/profile.d/admintools-ssl-certs.sh",
    owner   => $user,
    group   => $group,
    content => @("END")
      # Export location of SSL certs as environment variables, created by Puppet
      export SSL_CERT_DIR=/etc/ssl/certs
      export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
      | END
  }

}