swap
====

Change history
--------------

* v0.1.2
    * Run `swapoff -a` every time as instantaneous and can fail if run once
* v0.1.1
    * Allow for tabs or spaces in /etc/fstab
* v0.1.0
    * Made on-off operations one-time use /swapfile as semaphor
* v0.0.3
    * Added feature to leave swap state alone (size = 0) or disable (size = -1)
* v0.0.2
    * Improved comment clarity
* v0.0.1
    * Initial version, creates swap file and turns it on