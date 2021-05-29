usertools
=========

Change history
--------------

* v0.4.5
    * Added local and remote forwards to sshconfig
* v0.4.4
    * Added $ensure to sshconfig to allow removal of old lines
* v0.4.3
    * Added $additional_lines hash for putting anything into .ssh/config per host
* v0.4.2
    * Added $identity_file for nominating a specific key pair to use when SSHing to a named host
* v0.4.1
    * Brought .profile under management, depending on $manage_profile variable
* v0.4.0
    * Added $crons and $cron_defaults to allow user-specific scheduled tasks
* v0.3.9
    * Added title to usertools::write_keypair ensdir to cope with duplicate resources
* v0.3.8
    * Make all safe_repo cron tasks run at midnight, unless update_cadence overrides hour and/or minute
* v0.3.7
    * Introduced $require_package to force user (modifications) to wait for their package-based user creation
* v0.3.6
    * Made safe_repo files dependent upon the repo that they're checking out
    * Added $symlinks to create external references (e.g. artifact repo)
    * Added $ensure on safe_symlink to allow for absent
* v0.3.5
    * Made safe_repo resources user-safe, to allow two users to checkout the same repos
    * Made sshconfig more flexible to support wildcard host families
* v0.3.4
    * Parameterised TMOUT as $autologout to allow for global/per-user configuration
* v0.3.3
    * Made safe_directory more Linux-Windows tolerant by resolving user 'root' to 'Administrator'
* v0.3.2
    * Made safe_repos removable by adding $ensure
* v0.3.1
    * Added $update_cadence to safe_repo
* v0.3.0
    * Added $manage_repos kill switch to enable file sharing for vagrant VMs
* v0.2.5
    * Added $ensure to userkey to allow for key removal
* v0.2.4
    * Added $ensure to write_keypair to allow for key removal
* v0.2.3
    * Added feature to append required new-line character onto private key files
* v0.2.2
    * Deprecated moveout in favour of vagrant addition to rc.local
* v0.2.1
    * Introduced moveout hack to make room for users attached to a key UID (e.g. 1000)
* v0.2.0
    * Made write_keypair Windows-friendly
    * Standardised params across usertools and admintools
* v0.1.2
    * Wrapped safe_directory in ensure_resource and if !defined() to avoid duplicate definition
* v0.1.1
    * Create resolved_group/mode even if absenting the user to avoid warnings
* v0.1.0
    * Stopped creating (and removed) home directories for users being absented
* v0.0.16
    * Added $repos for checking out repos as this user
* v0.0.15
    * Added $sshconfigs to manage universal SSH configurations
* v0.0.14
    * Added support for loading keys into (pre-loaded) key agent
* v0.0.13
    * Added pass-through for target in strange .each iterator
* v0.0.12
    * Added Oracle Linux to list for matching
* v0.0.11
    * Parameterised colouring to control shorter_hostname domain removal (chophost)
* v0.0.10
    * Added new parameters for gitconfig
* v0.0.9
    * Rewrote bashaddition to cope with title collisions for usertools::user_defaults
* v0.0.8
    * Added bashaddition for adding lines to .bashrc and .bash_profile
* v0.0.7
    * Added new gitconfig options
* v0.0.6
    * Added $home_dir_root for off-root volume home directories
* v0.0.5
    * Added $manage_command_prompt and $manage_logout
    * $managehome now also managed .bash_profile
    * Added write_keypair.pp