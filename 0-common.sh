#!/bin/sh
OUT_DIR=out
K3S_CONFIG=$OUT_DIR/k3s.yaml
cyan='\033[36m'
white='\033[1m'
green='\033[32m'
red='\033[31m'
reset='\033[0m'

info() {
    echo "${green}$1${reset}"
}

trace() {
    echo "${white}$1${reset}"
}

error() {
    echo "${red}$1${reset}"
}
