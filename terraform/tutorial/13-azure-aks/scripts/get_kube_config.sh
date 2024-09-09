# get kubeconfig from AKS
resource_group_name=$(terraform output -raw test_resource_group_name)
az aks get-credentials --resource-group b9c51a852f8dbea3-rg --name e66c3fa9a3b80138-aks --file ~/.kube/config
# tell kubelogin to use Azure CLI
kubelogin convert-kubeconfig -l azurecli
# test
kubectl get nodes
