#!/bin/sh
set -uo pipefail
. ./0-common.sh

startMultipass() {
    vmCount=$(multipass list | grep k3s-spin | wc -l)

    if [ $vmCount = 1 ]
    then
        info "k3s-spin vm is already running!"
    else
        trace "Launching vm k3s-spin ..."
        multipass launch --name k3s-spin --cpus 4 --mem 8G --disk 20G 
        trace "Mounting local folder..."
        multipass mount ./ k3s-spin:/home/spin
    fi
    multipass info k3s-spin
}

startMultipass