harden
======

Change history
--------------

* v0.1.1
    * Removed rkhunter as advice is that it's of little use these days
* v0.1.0
    * Parameterised sshd service name for multi OS
* v0.0.6
    * Added touch to stop rkhunter running when rkhunter::cron_daily_run is false
* v0.0.5
    * Added onlyif attribute to harden::disable_user, as a user that does not exist cannot be disabled
* v0.0.4
    * Added variable stage_last::disable_osdefaultuser, false by default, but only accessible if !remove_osdefaultuser
* v0.0.3
    * Added variable stage_last::remove_osdefaultuser, true by default
* v0.0.2
    * Added Oracle Linux to list for matching
* v0.0.1
    * Initial version including SELinux, non-standard SSH ports, root login and rkhunter