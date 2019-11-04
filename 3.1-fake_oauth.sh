#!/bin/sh

set -ue
. ./0-common.sh

HOST_IP=''
UPDATE_OAUTH_SCRIPT=$OUT_DIR/update_spin_oauth.sh

# From: https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x
loadHostIp() {
    HOST_IP=$(ifconfig en0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
}

startUpFakeOauth() {
    fakeOauth=$(docker ps | grep fake-oauth | wc -l)
    
    if [ $fakeOauth = 1 ]
    then
        info 'fake-oauth server is already running!'
    else
        trace "Starting fake-oauth server..."
        docker run -d --rm --name fake-oauth -p 8282:8282  afcastano/fake-oauth2
    fi
}

shutDownFakeOauth() {
    fakeOauth=$(docker ps | grep fake-oauth | wc -l)
    
    if [ $fakeOauth = 1 ]
    then
        trace "Shutting down fake-oauth server..."
        docker stop fake-oauth
    else
        info "fake-oauth already shut down!"
    fi
}

generateHalScript() {
    cat > $UPDATE_OAUTH_SCRIPT << EOF
    #!/bin/bash
    hal config security authn oauth2 edit \
        --client-id dummy-client-id \
        --client-secret dummy-client-secret \
        --user-authorization-uri http://${HOST_IP}:8282/auth/request/path \
        --access-token-uri http://${HOST_IP}:8282/access/token/request \
        --user-info-uri http://${HOST_IP}:8282/userInfo \
        --user-info-mapping-email email \
        --user-info-mapping-first-name name \
        --user-info-mapping-last-name name \
        --user-info-mapping-username name     

    hal config security ui edit --override-base-url http://localhost:9000
    hal config security api edit --override-base-url http://localhost:8084
    hal config security authn oauth2 enable
    hal deploy apply        
EOF
}


authEnabled() {
    local enabled="$(kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "hal config security authn oauth2 --no-validate -q -o json" | jq -r -j '.enabled')"
    echo $enabled
}

## Local kubeconfig should be configured already.
# Source https://kb.armory.io/troubleshooting/file-based-authorization/
# Source https://www.spinnaker.io/setup/security/authentication/
configureSpinnaker() {
    local enabled="$(authEnabled)"
    if [ "$enabled" = "true" ]
    then
        info "Spinnaker authn already enabled!"                
    else
        trace "Enabling spinnaker authn..."
        generateHalScript
        kubectl --kubeconfig $K3S_CONFIG -n spin cp $UPDATE_OAUTH_SCRIPT spin/spin-spinnaker-halyard-0:/home/spinnaker
        kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "cd /home/spinnaker && chmod +x update_spin_oauth.sh && ./update_spin_oauth.sh"
    fi
}

## Local kubeconfig should be configured already.
# Source https://kb.armory.io/troubleshooting/file-based-authorization/
# Source https://www.spinnaker.io/setup/security/authentication/
disableAuthnSpinnaker() {
    local enabled="$(authEnabled)"
    if [ "$enabled" = "true" ]
    then
        trace "Disabling spinnaker authn..."
        kubectl --kubeconfig $K3S_CONFIG -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "hal config security authn oauth2 disable && hal deploy apply"
    else
        info "Spinnaker authn already disabled!"
    fi
}

disable() {
    disableAuthnSpinnaker
    shutDownFakeOauth
}

enable() {
    loadHostIp
    startUpFakeOauth
    configureSpinnaker
}

ACTION=enable
while getopts 'd' c
do
  case $c in
    d) ACTION=disable ;;
  esac
done
shift $((OPTIND-1))
$ACTION $@