Workstream
==========

Provisioned environment guide
-------
Out-of-the-box, Workstream provisions a large set of hosts and images.  The intention is that you'll edit down `main.tf` in the root Terraform module to the parts of the environment that you're interested in. 


Hosts
-----
If you build everything with Terraform, you'll get the following hosts created in AWS:

* `Bastion` - Bastion host for indirecting all environment SSH requests
  * A bastion host accessible directly by SSH.  The public IP will need to be gleaned from the EC2 Console or `terraform apply` output.
  * All other hosts will need to be accessed indirectly via the bastion host.  This can be achieved in a single SSH command line with a combination of a command proxy (`-o ProxyCommand="..."`) and SSH agent forwarding (`-A`).  e.g.
    * `ssh -A -o ProxyCommand='ssh -W %h:%p centos@<bastion_public_IP>' centos@<host_private_ip>`
  * Removing or disabling `Bastion` would effectively remove SSH access to all machines in the environment.
  * For all production environments, it's recommended that the SSH key for `Bastion` be regenerated and held exclusively by the team responsible for support of those environments (in emergency, break glass to access production machines by SSH).  
* `Packed` - Packer demo
  * Only accessible from the `Bastion`
  * Built from a packer-generated machine image (AMI)
* `Puppetmless` - Puppet demo (Masterless)
  * Only accessible from the `Bastion`
  * It installs puppet and its dependencies, then transfers the manifests in [/puppet](/puppet) to ```/etc/puppet```.  Puppet is run (masterless) to apply this configuration to this host.
* `Puppetmaster` - Puppet demo (Master)
  * [As per `puppetmless`] Only accessible from the `Bastion`
  * [As per `puppetmless`] It installs puppet and its dependencies, then transfers the manifests in [/puppet](/puppet) to ```/etc/puppet```.  Puppet is run (masterless) to apply this configuration to this host.
  * `Puppetmaster` does not have to be used as a Puppet master.  It is a config-managed server, but is built masterless and provides a general purpose guide for the masterless configuration of other hosts in the environment.
  * The `Puppetmaster` module outputs an SSH command line as part of the `terraform apply` run.
* `Ansiblelocal` - Ansible demo (Local)
  * Only accessible from the `Bastion`
  * It installs Ansible and its dependencies, then transfers the manifests in [/ansible](/ansible) to ```/etc/ansible```.
  * Ansible is executed (locally) to apply this configuration to this host.
* `Dockerhost` - Docker host demo
  * Only accessible from the `Bastion`
  * It installs Docker and Docker-compose.
  * Docker can only be run by the `dockeruser`.  `dockeruser` is a member of the `docker` group, but it's not the linux super-root (`root`).  However, bear in mind that any user that can run docker can run this:
    * command
    * This all means that you can't run docker commands with the default (`centos`) user:
      ```
      [centos@dockerhost ~]$ docker container ls
      Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.32/containers/json: dial unix /var/run/docker.sock: connect: permission denied
      ```
    * Instead you need to use `sudo` to run as `dockeruser`
      ```
      [centos@dockerhost ~]$ sudo -u dockeruser docker container ls
      CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
      ```

Packer AMIs
-----------
If you build each template with Packer, you'll get the following AMIs created in AWS:

* 'centos-updated-(timestamp)' - 