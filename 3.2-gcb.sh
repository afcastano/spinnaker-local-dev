#!/bin/sh

set -e
. ./0-common.sh

HOST_IP=''


# # ## Local kubeconfig should be configured already.
# # # Source https://kb.armory.io/troubleshooting/file-based-authorization/
# # # Source https://www.spinnaker.io/setup/security/authentication/
# # configureSpinnaker() {
# #     local enabled="$(authEnabled)"
# #     if [ "$enabled" = "true" ]
# #     then
# #         info "Spinnaker authn already enabled!"                
# #     else
# #         trace "Enabling spinnaker authn..."
# #         generateHalScript
# #         kubectl --kubeconfig $K3S_CONFIG -n spin cp $UPDATE_OAUTH_SCRIPT spin/spin-spinnaker-halyard-0:/home/spinnaker
# #         kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "cd /home/spinnaker && chmod +x update_spin_oauth.sh && ./update_spin_oauth.sh"
# #     fi
# # }

# ## Local kubeconfig should be configured already.
# # Source https://kb.armory.io/troubleshooting/file-based-authorization/
# # Source https://www.spinnaker.io/setup/security/authentication/
# disableAuthnSpinnaker() {
#     local enabled="$(authEnabled)"
#     if [ "$enabled" = "true" ]
#     then
#         trace "Disabling spinnaker authn..."
#         kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "hal config security authn oauth2 disable && hal deploy apply"
#     else
#         info "Spinnaker authn already disabled!"
#     fi
# }

# disable() {
#     disableAuthnSpinnaker
#     shutDownFakeOauth
# }

enableIgorLocking() {
    cat > $OUT_DIR/igor-local.yml << EOF
locking:
    enabled: true
EOF
    trace "Adding locking to igor-local..."
    kubectl cp $OUT_DIR/igor-local.yml spin/spin-spinnaker-halyard-0:/home/spinnaker/.hal/default/profiles
}

authEnabled() {
    local enabled="$(kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c " --no-validate -q -o json" | jq -r -j '.enabled')"
    echo $enabled
}

enableGgb() {
    trace "Enabling GCB..."
    cat > $OUT_DIR/update_spin_gcb.sh << EOF
    #!/bin/bash
    hal config pubsub google enable

    hal config ci gcb enable
    
    hal deploy apply
EOF
    kubectl cp $OUT_DIR/update_spin_gcb.sh spin/spin-spinnaker-halyard-0:/home/spinnaker
    kubectl -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "cd /home/spinnaker && chmod +x update_spin_gcb.sh && ./update_spin_gcb.sh"
}

createAccount() {
    ACCOUNT_NAME=$1
    PROJECT_ID=$2
    SUBSCRIPTION_NAME=$3
    SERVICE_ACCOUNT_KEY=$4
    trace "Adding account ${ACCOUNT_NAME}... with: $1, $2, $3, $4"
    cat > $OUT_DIR/gcb_account_${ACCOUNT_NAME}.bash << EOF
    #!/bin/bash
    hal config ci gcb account add $ACCOUNT_NAME \
      --project $PROJECT_ID \
      --subscription-name $SUBSCRIPTION_NAME \
      --json-key /home/spinnaker/${ACCOUNT_NAME}.json
EOF
    kubectl cp $OUT_DIR/gcb_account_${ACCOUNT_NAME}.bash spin/spin-spinnaker-halyard-0:/home/spinnaker
    trace "Copying service account key..."
    kubectl cp $SERVICE_ACCOUNT_KEY spin/spin-spinnaker-halyard-0:/home/spinnaker/${ACCOUNT_NAME}.json
    trace "Applying account..."
    kubectl -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "cd /home/spinnaker && chmod +x gcb_account_${ACCOUNT_NAME}.bash && ./gcb_account_${ACCOUNT_NAME}.bash"
}

enable() {
    enableIgorLocking
    createAccount $@
    enableGgb
}

ACTION=enable
while getopts 'de' c
do
  case $c in
    d) ACTION=disable ;;
    e) ACTION=enable ;;
  esac
done

shift $((OPTIND-1))

$ACTION $@