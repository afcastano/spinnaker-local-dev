.SILENT: 
.DEFAULT_GOAL := help

help: ## This help
	echo "\033[31mSet up spinnaker for local development using Multipass and k3s"
	echo ""
	echo "\033[0mTargets:"
	echo "----------------"
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)


start-multipass: ## Creates a multipass VM and starts it.
	sh 1-start_multipass.sh

install-k3s: start-multipass ## Installs k3s in the multipass instance
	$(call multipassExec,./2-install_k3s.sh)
	sh 2.1-configure_host_kube.sh

install-spinnaker: ## Install spinnaker using the helm chart
	$(call multipassExec,./3-install_spinnaker.sh)

enable-fake-oauth: ## Enables fake oauth in spinnaker
	sh 3.1-fake_oauth.sh

disable-fake-oauth: ## Disables fake oauth in spinnaker
	sh 3.1-fake_oauth.sh -d
	
delete-spinnaker: ## Deletes the spinnaker instance in k3s
	$(call multipassExec,./3-install_spinnaker.sh -d)

clean-up: ## Deletes the multipass vm and everything inside.
	sh 99-clean_up.sh

define multipassExec
	multipass exec k3s-spin -- sh -c "cd /home/spin && sudo $1"
endef