
define devtools::run_ruby (

  # specify commands with full paths for all non-ruby/gem binaries
  $command = $title,
  $path = ['/opt/rh/rh-ruby25/root/usr/bin','/opt/rh/rh-ruby25/root/usr/local/bin', '/sbin', '/bin', '/usr/sbin', '/usr/bin', '/usr/local/bin/'],
  $ruby_path = '/opt/rh/rh-ruby25/root',
  $onlyif = undef,
  $envvars = lookup('devtools::run_ruby::envvars', undef, undef, '')

) {

  include 'devtools::languages::ruby'

  exec { "devtools-run_ruby-${title}":
    path => $path,
    user => 'root',
    command => "bash -c \"LD_LIBRARY_PATH=${ruby_path}/usr/lib64 ${envvars} ${command}\"",
    onlyif => $onlyif,
  }

}
