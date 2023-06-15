terraform init
terraform apply

aws eks update-kubeconfig --name $(terraform output -raw cluster_name)
kubectl get svc

helm install my-minecraft -f helm-values.yaml minecraft-server-charts/minecraft

CONN = kubectl get svc --namespace default my-minecraft-minecraft | grep my-minecraft-minecraft | awk '{ print $4 }'
echo "THE MINECRAFT SERVER IS ACCESSIBLE AT: $CONN"
