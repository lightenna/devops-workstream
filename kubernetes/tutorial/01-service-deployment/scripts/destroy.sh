# change into parent directory if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd
# set up KUBECONFIG (requires build of Terraform tutorial 13 first)
export KUBECONFIG="${cwd}/../../../terraform/tutorial/13-azure-simple-aks/.local-kube-config"
echo "export KUBECONFIG=\"${cwd}/../../../terraform/tutorial/13-azure-simple-aks/.local-kube-config\""
# destroy service
kubectl delete -f ./hello-service.yaml;
# destroy create pods
kubectl delete -f ./hello-deployment.yaml;
# verify the pods are gone
echo 'kubectl get pods'
kubectl get pods
