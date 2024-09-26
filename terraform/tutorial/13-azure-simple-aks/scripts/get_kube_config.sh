fname="./.local-kube-config"
# read cluster variables out from last terraform run
resource_group_name=$(terraform output -raw resource_group_name)
kubernetes_cluster_name=$(terraform output -raw kubernetes_cluster_name)
az aks list \
  --resource-group $resource_group_name \
  --query "[].{\"K8s cluster name\":name}" \
  --output table
# get kubeconfig
echo "$(terraform output kube_config)" | grep -v 'EOT' > ${fname}
export KUBECONFIG="${fname}"
echo
echo "To interact with the '${kubernetes_cluster_name}' cluster, set up the KUBECONFIG environment variable:"
echo "export KUBECONFIG=\"${fname}\""
echo
# list out the nodes that make up this cluster
kubectl get nodes
