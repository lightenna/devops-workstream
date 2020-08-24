
define dodocker::write_cert (
  # duplicated for dodocker::write_cert, webtools::write_cert and puppetmaster::write_cert
  $cert_name = $title,
  $cert_directory_path = '/etc/pki/tls/certs',
  $key_directory_path = '/etc/pki/tls/private',
  $user = 'root',
  $group = 'root',
  $mode = '0640',
  $mode_dir = '0755',
  $certificate,
  $key,
  $ca_bundle,

) {

  File {
    owner => $user,
    group => $group,
    mode  => $mode,
  }

  $filename_certificate = "${cert_directory_path}/${cert_name}.crt"
  $filename_cabundle = "${cert_directory_path}/${cert_name}.ca-bundle"
  $filename_key = "${key_directory_path}/${cert_name}.key"

  # ensure that the target directory exist
  if ! defined(Usertools::Safe_directory["${cert_directory_path}"]) {
    ensure_resource(usertools::safe_directory, "${cert_directory_path}", { mode => $mode_dir, })
    ensure_resource(usertools::safe_directory, "${key_directory_path}", { mode => $mode_dir, })
  }

  # create certificate files
  if ! defined(File["${filename_key}"]) {
    file { "${filename_key}":
      content => $key,
      require => [File["${key_directory_path}"]],
    }
  }
  if ! defined(File["${filename_certificate}"]) {
    file { "${filename_certificate}":
      content => $certificate,
      require => [File["${cert_directory_path}"]],
    }
  }
  if ! defined(File["${filename_cabundle}"]) {
    file { "${filename_cabundle}":
      content => $ca_bundle,
      require => [File["${cert_directory_path}"]],
    }
  }

}

