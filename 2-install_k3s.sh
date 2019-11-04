#!/bin/sh

# This script should be run inside multipass

set -u
. ./0-common.sh

installK3s() {
    command -v k3s
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        info "k3s is already installed!"
    else
        trace "Installing k3s ..."
        curl -sfL https://get.k3s.io/ | INSTALL_K3S_VERSION=v0.9.1 sh -
    fi    
}

installHelm() {
    command -v helm
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        info "helm is already installed!"
    else
        trace "Installing helm ..."
        curl -sLo $OUT_DIR/helm-v2.15.2-linux-amd64.tar.gz https://get.helm.sh/helm-v2.15.2-linux-amd64.tar.gz
        tar -zxvf $OUT_DIR/helm-v2.15.2-linux-amd64.tar.gz  --no-same-owner -C $OUT_DIR
        sudo mv $OUT_DIR/linux-amd64/helm /usr/local/bin/helm
    fi    
}

configureLocalStorage() {
    localStorageCount=$(kubectl get namespaces | grep local-path-storage | wc -l)

    if [ $localStorageCount = 1 ]
    then
        info "Local storage is already set up!"
    else
        trace "Setting up local storage..."
        LOCAL_STORAGE=$OUT_DIR/local-path-storage.yaml
        curl -L  https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml -o $LOCAL_STORAGE

        trace "Apply local storage"
        kubectl apply -f $LOCAL_STORAGE
        sleep 5
        kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    fi
}

printAllResources() {
    trace "Following you should see all namespaces:"
    kubectl get namespaces
    RESULT=$?
    if [ $RESULT -eq 0 ]
    then
        trace "----------"
        info "k3s configured correctly:"
        echo "${white}export KUBECONFIG=${cyan}$K3S_CONFIG${reset}"
    else
        error "Error configuring k3s"
        exit 1
    fi    
}


mkdir -p $OUT_DIR
installK3s
installHelm
configureLocalStorage
printAllResources