
define usertools::autologout (

  $user = $title,
  $tmout = 3540,
  $home,

) {

  if ($tmout != -1) {
    concat::fragment { "usertools-autologout-bashrc-${user}":
      target  => "${home}/.bashrc",
      order   => '30',
      content => @("END")
        # add auto-logout after 59 minutes
        export TMOUT=${tmout}
        | END
    }
  }
}
