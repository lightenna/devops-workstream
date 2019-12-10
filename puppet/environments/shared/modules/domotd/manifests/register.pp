define domotd::register(

  $content = $name,
  $order = 10,
  $motd = undef,
  $motd_template = undef,
  $append = ' ',

) {

  # defined types can't inherit
  include domotd::params
  $resolved_motd = $motd ? {
    undef => $domotd::params::motd,
    default => $motd,
  }
  $resolved_motd_template = $motd_template ? {
    undef => $domotd::params::motd_template,
    default => $motd_template,
  }

  # add content directly to /etc/motd
  if defined(Concat["${resolved_motd}"]) {
    # add fragment to target file
    concat::fragment{"motd_fragment_$name":
      target  => $resolved_motd,
      content => "${content}${append}",
      order => $order,
    }
  }

  # also add content to /etc/motd.template
  if defined(Concat["${resolved_motd_template}"]) {
    concat::fragment{"motd_fragment_template_$name":
      target  => "${resolved_motd_template}",
      content => "${content}${append}",
      order => $order,
    }
  }

}

