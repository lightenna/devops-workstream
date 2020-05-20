
class dopostfix (

  $myorigin = "${::fqdn}",
  $relayhost = 'localhost',
  $enable_tls = true,
  $smtp_username = undef,
  $smtp_password = undef,

) {

  class { '::postfix' :
    myorigin => $myorigin,
  }

  # install deps for TLS
  case $operatingsystem {
    centos, redhat, oraclelinux, fedora: {
      ensure_packages(['cyrus-sasl-plain'], {})
    }
    ubuntu, debian: {
      ensure_packages(['libsasl2-modules'], {})
    }
  }

  # configure postfix
  postfix::config {
    'relayhost': value => $relayhost;
    # 'myorigin' is already defined
  }

  if ($enable_tls) {
    postfix::config {
      'smtp_tls_security_level': value => 'encrypt';
      'smtp_tls_CAfile': value => '/etc/pki/tls/certs/ca-bundle.crt';
      'smtp_tls_session_cache_database': value => 'btree:${data_directory}/smtp_scache';
      'smtp_sasl_auth_enable': value => 'yes';
      'smtp_sasl_security_options': value => 'noanonymous';
      'smtp_sasl_tls_security_options': value => 'noanonymous';
      'smtp_sasl_password_maps': value => 'hash:/etc/postfix/sasl_passwd';
      'smtp_tls_note_starttls_offer': value => 'yes';
    }
  }

  if ($smtp_username != undef) {
    # encrypt password
    postfix::hash { '/etc/postfix/sasl_passwd':
      content => @("END")
      # SMTP auth, only used for hosts that require it
      # host  smtp_username:smtp_password
      ${relayhost}  ${$smtp_username}:${smtp_password}
      | END
    }
  }

}
