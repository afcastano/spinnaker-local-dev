#!/bin/sh
set -ue
. ./0-common.sh

kubectl --kubeconfig $K3S_CONFIG delete namespace $NAMESPACE