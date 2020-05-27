#!/usr/bin/env bash
# remove all containers from node
# can therefore be used to remove rancher agent from cluster nodes
# https://rancher.com/docs/rancher/v2.x/en/cluster-admin/cleaning-cluster-nodes/

# check that running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# stop the docker monitor service
systemctl stop $(systemctl list-unit-files | grep dockersp | awk -F'.' '{ print $1; }')

# stop and all containers
docker container stop $(docker container ls -aq) && docker system prune --force

# delete all containers, images and volumes
docker rm -f $(docker ps -qa)
docker rmi -f $(docker images -q)
docker volume rm $(docker volume ls -q)

# unmount all mount points
for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done

# delete all created files
rm -rf /etc/ceph \
       /etc/cni \
       /etc/kubernetes \
       /opt/cni \
       /opt/rke \
       /run/secrets/kubernetes.io \
       /run/calico \
       /run/flannel \
       /var/lib/calico \
       /var/lib/etcd \
       /var/lib/cni \
       /var/lib/kubelet \
       /var/lib/rancher/rke/log \
       /var/log/containers \
       /var/log/pods \
       /var/run/calico

# restart stopped services
systemctl start $(systemctl list-unit-files | grep dockersp | awk -F'.' '{ print $1; }')
