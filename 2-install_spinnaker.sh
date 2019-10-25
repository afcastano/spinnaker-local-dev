echo fetching spinnaker helm chart
helm fetch stable/spinnaker --version=1.16.1
echo templating helm chart
helm template --name spin --namespace spin  --values values.yaml spinnaker-1.16.1.tgz > spinnaker.yaml
echo applying chart
kubectl --kubeconfig k3s.yaml create namespace spin
kubectl --kubeconfig k3s.yaml apply -f spinnaker.yaml -n spin
kubectl --kubeconfig k3s.yaml get pods -n spin
