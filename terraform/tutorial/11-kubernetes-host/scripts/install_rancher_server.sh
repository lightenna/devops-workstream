# install some management pre-requisites
sudo yum install -y epel-release
sudo yum install -y htop wget deltarpm
# turn off machine firewall (accept all traffic within NSG)
sudo iptables -I INPUT -j ACCEPT
sudo iptables -F
# docker install
sudo bash -c 'curl -fsSL https://get.docker.com/ | sh'
# docker-compose install
sudo curl -L \"https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# add admin user (however provisioned) to docker group to allow it to run docker commands
sudo usermod -aG docker rootlike
sudo usermod -aG docker vagrant
# start docker service and enable it!
sudo systemctl --now enable docker
# turn off SELinux
sudo setenforce 0
# [OPTIONAL] install CSF
# sudo bash -c 'cd /usr/src && rm -fv csf.tgz && wget https://download.configserver.com/csf.tgz && tar -xzf csf.tgz && cd csf && sh install.sh'
# [OPTIONAL] add swap to make tiny VM more conducive for supporting a single-node cluster (note: not production)
# sudo dd if=/dev/zero of=/swapfile bs=4096 count=1048576
# sudo chmod 600 /swapfile
# sudo mkswap /swapfile
# sudo swapon /swapfile
# sudo sysctl vm.swappiness=10
# install Rancher server
sudo docker run -d --privileged --restart=unless-stopped -p 80:80 -p 8443:443 rancher/rancher:v2.4.11

