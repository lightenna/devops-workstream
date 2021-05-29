#!/usr/bin/env bash
# remove Rancher agent and all derived containers

# find all rancher containers, except rancher server
GREP_FIND='rancher\|k8s'
GREP_IGNORE='rancher/rancher:'

# check that running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# delete all containers
docker rm -f $(docker container ls -a | grep ${GREP_FIND} | grep -v ${GREP_IGNORE} | awk ' { print $1; } ')

# clean up unused volumes without confirmation
docker volume prune --force

# clean up other Kubernetes artefacts
for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done
cleanupdirs="/etc/ceph /etc/cni /etc/kubernetes /opt/cni /opt/rke /run/secrets/kubernetes.io /run/calico /run/flannel /var/lib/calico /var/lib/etcd /var/lib/cni /var/lib/kubelet /var/lib/rancher/rke/log /var/log/containers /var/log/pods /var/run/calico"
for dir in $cleanupdirs; do
  echo "Removing $dir"
  rm -rf $dir
done
cleanupinterfaces="flannel.1 cni0 tunl0"
for interface in $cleanupinterfaces; do
  echo "Deleting $interface"
  ip link delete $interface
done
if [ "$1" = "flush" ]; then
  echo "Parameter flush found, flushing all iptables"
  iptables -F -t nat
  iptables -X -t nat
  iptables -F -t mangle
  iptables -X -t mangle
  iptables -F
  iptables -X
  /etc/init.d/docker restart
else
  echo "Parameter flush not found, iptables not cleaned"
fi
