#!/bin/sh

# Kubectl should be already configured. To be run inside multipass

set -u
. ./0-common.sh

CHART=$OUT_DIR/spinnaker-1.16.1.tgz
SPINNAKER=$OUT_DIR/spinnaker.yaml

spinnakerRunning() {
    local running=$(kubectl -n spin get -o template pod spin-spinnaker-halyard-0 --template={{.status.phase}} --ignore-not-found)
    if [ "$running" = "Running" ]
    then
        echo "true"
    else
        echo "false"
    fi
}

installSpinnaker() {
    local isRunning="$(spinnakerRunning)"
    if [ "$isRunning" = "true" ]
    then
        info "Spinnaker is already running!"                
    else
        trace "Spinnaker is not running..."
        # Throw Error if config is invalid
        trace 'init helm...'
        helm init -c
        trace 'fetching spinnaker helm chart...'
        helm fetch stable/spinnaker --version=1.16.1 --destination $OUT_DIR

        trace 'templating helm chart...'
        helm template --name spin --namespace spin  --values values.yaml $CHART > $SPINNAKER

        trace 'creating namespace...'
        kubectl create namespace $NAMESPACE --dry-run -o yaml > $OUT_DIR/namespace.yaml
        kubectl apply -f $OUT_DIR/namespace.yaml

        trace applying chart...
        kubectl apply -f $SPINNAKER -n $NAMESPACE
        sleep 5
        kubectl get pods -n $NAMESPACE
    fi    
}

deleteSpinnaker() {
    local isRunning="$(spinnakerRunning)"
    if [ "$isRunning" = "true" ]
    then
        trace "Deleting spinnaker..."
        kubectl delete namespace $NAMESPACE
    else
        info "Spinnaker is already deleted!"                
    fi
}

ACTION=installSpinnaker
while getopts 'd' c
do
  case $c in
    d) ACTION=deleteSpinnaker ;;
  esac
done
shift $((OPTIND-1))
$ACTION $@