#!/bin/sh

echo "Launching vm k3s-spin"
multipass launch --name k3s-spin --cpus 4 --mem 8G --disk 20G
echo "Installing k3s"
multipass exec k3s-spin -- sh -c "curl -sfL https://get.k3s.io/ | INSTALL_K3S_VERSION=v0.9.1 sh -"
echo "Copying kube config"
multipass exec k3s-spin -- sh -c "sudo cp /etc/rancher/k3s/k3s.yaml . && sudo chmod a=r k3s.yaml"
multipass copy-files k3s-spin:k3s.yaml k3s.yaml
echo "Updating kube config"
K3S_IP=$(multipass info k3s-spin --format json | jq -r '.info."k3s-spin".ipv4[0]')
sed -i -e "s/127.0.0.1/${K3S_IP}/g" k3s.yaml
rm k3s.yaml-e
echo "Setting up local storage"
curl -LO  https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
echo "Apply local storage"
kubectl --kubeconfig k3s.yaml apply -f local-path-storage.yaml
sleep 5
kubectl --kubeconfig k3s.yaml patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
rm local-path-storage.yaml
echo "Following you should see all installed resources"
kubectl --kubeconfig k3s.yaml get all --all-namespaces