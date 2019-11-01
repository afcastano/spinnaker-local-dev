.SILENT: 
.DEFAULT_GOAL := help

help: ## This help
	echo "\033[31mSet up spinnaker for local development using Multipass and k3s"
	echo ""
	echo "\033[0mTargets:"
	echo "----------------"
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


start-multipass: ## Creates a multipass VM and starts it.
	sh 1-start_multipass.sh

install-k3s: start-multipass ## Installs k3s in the multipass instance
	$(call multipassExec,./2-install_k3s.sh)

install-spinnaker: install-k3s ## Install spinnaker using the helm chart
	$(call multipassExec,./3-install_spinnaker.sh)

configure-host-kubeconfig: ## Configures the host kubeconfig file to point to k3s
	sh 4-configure_host_kube.sh

delete-spinnaker: ## Deletes the spinnaker instance in k3s
	$(call multipassExec, ./98-delete-spinnaker.sh)

clean-up: ## Deletes the multipass vm and everything inside.
	99-clean_up.sh

define multipassExec
	multipass exec k3s-spin -- sh -c "cd /home/spin && sudo $1"
endef