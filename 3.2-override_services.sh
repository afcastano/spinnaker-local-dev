UPDATE_ARTIFACT_SCRIPT=$OUT_DIR/update_artifact.sh
FILENAME="${1}.yml"
IMAGE=$2
echo "Overriding $FILENAME with image $IMAGE"

generateArtifactScript() {
    cat > $UPDATE_ARTIFACT_SCRIPT << EOF
    #!/bin/bash
    if test -f "~/.hal/default/service-settings/${FILENAME}"
    then
        sed -i '/artifactId:/d' ~/.hal/default/service-settings/${FILENAME}
    fi
    echo "artifactId: ${IMAGE}">>~/.hal/default/service-settings/${FILENAME}
    hal deploy apply
EOF
}

generateArtifactScript
kubectl -n spin cp $UPDATE_ARTIFACT_SCRIPT spin/spin-spinnaker-halyard-0:/home/spinnaker
kubectl -n spin exec -it spin-spinnaker-halyard-0 -- bash -c "cd /home/spinnaker && chmod +x .$UPDATE_ARTIFACT_SCRIPT && .$UPDATE_ARTIFACT_SCRIPT"