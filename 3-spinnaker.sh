#!/bin/sh

# Kubectl should be already configured. To be run inside multipass

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
    if [ "$isRunning" = "false" ]
    then
        trace "Deleting spinnaker..."
        kubectl delete namespace $NAMESPACE
    else
        info "Spinnaker is already deleted!"                
    fi
}

portForwardSpinnaker() {
    kubectl -n spin port-forward service/spin-gate 8084 &
    echo $! > $OUT_DIR/gate.pid
    info "Gate running at http://localhost:8084..."
    kubectl -n spin port-forward service/spin-deck 9000 &
    echo $! > $OUT_DIR/deck.pid
    info "Spinnaker running at http://localhost:9000..."
}

stopPortForwardSpinnaker() {
    trace "Stopping gate port forward..."
    kill -9 $(cat ${OUT_DIR}/gate.pid)
    rm ${OUT_DIR}/gate.pid

    trace "Stopping deck port forward..."
    kill -9 $(cat ${OUT_DIR}/deck.pid)
    rm ${OUT_DIR}/deck.pid

    info "Spinnaker port forward stopped"
}

unset INSTALL
unset DELETE
unset STOP_PORT_FORWARD
unset PORT_FORWARD

while getopts 'idsf' c
do
  case $c in
    i) INSTALL=true ;;
    d) DELETE=true ;;
    s) STOP_PORT_FORWARD=true ;;      
    f) PORT_FORWARD=true ;;      
  esac
done
shift $((OPTIND-1))

if [ $INSTALL ]; then
  installSpinnaker
fi

if [ $DELETE ]; then
  deleteSpinnaker
fi

if [ $STOP_PORT_FORWARD ]; then
  stopPortForwardSpinnaker
fi

if [ $PORT_FORWARD ]; then
  portForwardSpinnaker
fi


