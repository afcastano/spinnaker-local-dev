#!/bin/sh
set -u
. ./0-common.sh

CHART=$OUT_DIR/spinnaker-1.16.1.tgz
SPINNAKER=$OUT_DIR/spinnaker.yaml

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
