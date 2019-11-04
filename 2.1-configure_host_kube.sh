#!/bin/sh
set -ue
. ./0-common.sh

configureKubectl() {
    trace "Copying kube config..."
    mkdir -p $OUT_DIR
    multipass exec k3s-spin -- sh -c "sudo cp /etc/rancher/k3s/k3s.yaml /home/spin/$OUT_DIR && sudo chmod a=r /home/spin/$OUT_DIR/k3s.yaml"

    trace "Updating kube config..."
    K3S_IP=$(multipass info k3s-spin --format json | jq -r '.info."k3s-spin".ipv4[0]')
    sed -i -e "s/127.0.0.1/${K3S_IP}/g" $K3S_CONFIG
    
    info "Local kube configured. Update your KUBECONFIG:"
    echo "${white}export KUBECONFIG=${cyan}$(pwd)/$K3S_CONFIG${reset}"
}

configureKubectl