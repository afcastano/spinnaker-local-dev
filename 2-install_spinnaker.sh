#!/bin/sh
source 0-common.sh

NAMESPACE="${NAMESPACE:-spin}"

CHART=$OUT_DIR/spinnaker-1.16.1.tgz
SPINNAKER=$OUT_DIR/spinnaker.yaml

# Throw Error if config is invalid

echo fetching spinnaker helm chart...
helm fetch stable/spinnaker --version=1.16.1 --destination $OUT_DIR

echo templating helm chart...
helm template --name spin --namespace spin  --values values.yaml $CHART > $SPINNAKER

echo creating namespace...
kubectl --kubeconfig $K3S_CONFIG create namespace $NAMESPACE --dry-run -o yaml > $OUT_DIR/namespace.yaml
kubectl apply -f $OUT_DIR/namespace.yaml

echo applying chart...
kubectl --kubeconfig $K3S_CONFIG apply -f $SPINNAKER -n $NAMESPACE
sleep 5
kubectl --kubeconfig $K3S_CONFIG get pods -n $NAMESPACE
