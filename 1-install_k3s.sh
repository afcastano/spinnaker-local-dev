#!/bin/sh
cyan='\033[36m'
white="\033[1m"
reset='\033[0m'
clusterName='spin-k3s'
clusterCount=$(k3d l | grep k3s-default | wc -l)
echo $clusterCount
if [ $clusterCount = 1 ]
then
    echo "k3d cluster already exist..."
else
    echo "Creating k3d cluster..."    
    k3d create --image rancher/k3s:v0.9.1
fi

echo "Following you should see all installed resources"
KUBECONFIG="$(k3d get-kubeconfig --name='k3s-default')"
kubectl --kubeconfig=$KUBECONFIG get all --all-namespaces
RESULT=$?
if [ $RESULT -eq 0 ]
then
    echo "----------"
    echo "k3s configured correctly, configure your kubectl by running:"
    echo "${white}export KUBECONFIG=${cyan}\$(k3d get-kubeconfig --name='k3s-default')${reset}"
    exit 0
fi
echo "Error configuring k3s"
exit 1