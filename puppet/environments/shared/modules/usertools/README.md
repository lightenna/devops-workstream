usertools
=========

Change history
--------------

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