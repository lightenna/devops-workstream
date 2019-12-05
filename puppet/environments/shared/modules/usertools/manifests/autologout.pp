
define usertools::autologout (

  $user = $title,
  $home,

) {

  concat::fragment { "usertools-autologout-bashrc-${user}":
    target  => "${home}/.bashrc",
    order => '30',
    content => @(END)
        # add auto-logout after 59 minutes
        export TMOUT=3540
        | END
  }
}
