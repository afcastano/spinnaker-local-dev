echo fetching spinnaker helm chart
helm fetch stable/spinnaker --version=1.16.1
echo templating helm chart
helm template --name spin --namespace spin  --values values.yaml spinnaker-1.16.1.tgz > spinnaker.yaml
echo applying chart
KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
kubectl create namespace spin
kubectl apply -f spinnaker.yaml -n spin
kubectl get pods -n spin
