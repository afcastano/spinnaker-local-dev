#!/bin/sh
set -uo pipefail

source 0-common.sh

startMultipass() {
    vmCount=$(multipass list | grep k3s-spin | wc -l)

    if [ $vmCount = 1 ]
    then
        info "k3s-spin vm is already running!"
    else
        trace "Launching vm k3s-spin ..."
        multipass launch --name k3s-spin --cpus 4 --mem 8G --disk 20G
    fi
}

installK3s() {
    multipass exec k3s-spin -- sh -c 'command -v k3s'
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        info "k3s is already installed!"
    else
        trace "Installing k3s ..."
        multipass exec k3s-spin -- sh -c "curl -sfL https://get.k3s.io/ | INSTALL_K3S_VERSION=v0.9.1 sh -"
    fi    
}

installHelm() {
    multipass exec k3s-spin -- sh -c "command -v helm"
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        info "helm is already installed!"
    else
        trace "Installing helm ..."
        multipass exec k3s-spin -- sh -c "curl -sLo helm-v2.15.2-linux-amd64.tar.gz https://get.helm.sh/helm-v2.15.2-linux-amd64.tar.gz && tar -zxvf helm-v2.15.2-linux-amd64.tar.gz && sudo mv linux-amd64/helm /usr/local/bin/helm"
    fi    
}

configureKubectl() {
    trace "Copying kube config..."
    multipass exec k3s-spin -- sh -c "sudo cp /etc/rancher/k3s/k3s.yaml . && sudo chmod a=r k3s.yaml"
    mkdir -p $OUT_DIR
    multipass copy-files k3s-spin:k3s.yaml $K3S_CONFIG

    trace "Updating kube config..."
    K3S_IP=$(multipass info k3s-spin --format json | jq -r '.info."k3s-spin".ipv4[0]')
    sed -i -e "s/127.0.0.1/${K3S_IP}/g" $K3S_CONFIG
}

configureLocalStorage() {
    localStorageCount=$(kubectl --kubeconfig $K3S_CONFIG get serviceaccount local-path-provisioner-service-account -n local-path-storage | grep local-path-provisioner-service-account | wc -l)

    if [ $localStorageCount = 1 ]
    then
        info "Local storage is already set up!"
    else
        trace "Setting up local storage..."
        LOCAL_STORAGE=$OUT_DIR/local-path-storage.yaml
        curl -L  https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml -o $LOCAL_STORAGE

        trace "Apply local storage"
        kubectl --kubeconfig $K3S_CONFIG apply -f $LOCAL_STORAGE
        sleep 5
        kubectl --kubeconfig $K3S_CONFIG patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    fi
}

printAllResources() {
    trace "Following you should see all installed resources:"
    kubectl --kubeconfig $K3S_CONFIG get all --all-namespaces
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        trace "----------"
        info "k3s configured correctly, configure your kubectl by running:"
        echo "${white}export KUBECONFIG=${cyan}$K3S_CONFIG${reset}"
        exit 0
    fi
    error "Error configuring k3s"
    exit 1
}



startMultipass
installK3s
installHelm
configureKubectl
configureLocalStorage
printAllResources