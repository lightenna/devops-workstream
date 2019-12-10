
define devtools::user (

  $user = $title,

) {

  # don't do this because it breaks forwarded SSH keys after later session exited
  if (false) {
    # set up screen-compatible SSH_AUTH_SOCK
    if defined(Concat["/home/${user}/.bashrc"]) {
      concat::fragment { 'devtools-bashrc-sshsock':
        target  => "/home/${user}/.bashrc",
        content => @("BASHRCSOCK"/L)
          # create a symlink to the ssh-agent socket, for screen sessions
          if [ -S "$SSH_AUTH_SOCK" ] && [ ! -h "$SSH_AUTH_SOCK" ]; then
              ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh_auth_sock
              export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock
          fi
        | BASHRCSOCK
        order   => '20',
      }
    }
  }

}
