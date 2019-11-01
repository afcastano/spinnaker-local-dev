#!/bin/sh
set -ue
. ./0-common.sh

trace "Deleting k3s-spin instance"
multipass delete k3s-spin
multipass purge
multipass list
rm -rf out
info "Done"