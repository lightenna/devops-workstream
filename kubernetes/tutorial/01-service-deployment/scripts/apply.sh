# change into parent directory if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd
# set up KUBECONFIG (requires build of Terraform tutorial 13 first)
export KUBECONFIG="${cwd}/../../../terraform/tutorial/13-azure-simple-aks/.local-kube-config"
echo "export KUBECONFIG=\"${cwd}/../../../terraform/tutorial/13-azure-simple-aks/.local-kube-config\""
# apply the deployment to create pods
kubectl apply -f ./hello-deployment.yaml;
# verify the pods are there
echo 'kubectl get pods'
kubectl get pods
# create a service based on those pods
kubectl apply -f ./hello-service.yaml;
echo 'kubectl get service hello-kubernetes-first --watch'
kubectl get service hello-kubernetes-first --watch
