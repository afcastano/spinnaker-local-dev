#!/bin/sh

echo "Deleting k3s-spin instance"
multipass delete k3s-spin
multipass purge
multipass list
[ -f k3s.yaml ] && rm k3s.yaml
echo "Done"