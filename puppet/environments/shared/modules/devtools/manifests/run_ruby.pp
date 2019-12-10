
define devtools::run_ruby (

  # specify commands with full paths for all non-ruby/gem binaries
  $command = $title,
  $path = ['/opt/rh/rh-ruby25/root/usr/bin','/opt/rh/rh-ruby25/root/usr/local/bin', '/bin', '/usr/bin', '/usr/local/bin/'],
  $ruby_path = '/opt/rh/rh-ruby25/root',
  $onlyif = undef,

) {

  exec { "devtools-run_ruby-${title}":
    path => $path,
    command => "bash -c \"LD_LIBRARY_PATH=${ruby_path}/usr/lib64 ${command}\"",
    onlyif => $onlyif,
  }

}
