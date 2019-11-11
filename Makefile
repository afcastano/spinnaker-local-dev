.SILENT: 
.DEFAULT_GOAL := help

help: ## This help
	echo "\033[31mSet up spinnaker for local development using Multipass and k3s"
	echo ""
	echo "\033[0mTargets:"
	echo "----------------"
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9%_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start-multipass: ## Creates a multipass VM and starts it.
	sh 1-start_multipass.sh

install-k3s: start-multipass ## Installs k3s in the multipass instance
	$(call multipassExec,./2-install_k3s.sh)
	sh 2.1-configure_host_kube.sh

install-spinnaker: ## Install spinnaker using the helm chart
	$(call multipassExec, ./3-spinnaker.sh -i)

enable-fake-oauth: ## Enables fake oauth in spinnaker
	sh 3.1-fake_oauth.sh

enable-gcb: ## Enables gcb in spinnaker. Requires: $ACCOUNT_NAME, $PROJECT_ID, $SUBSCRIPTION_NAME, $SERVICE_ACCOUNT_KEY
	$(call multipassExec, ./3.2-gcb.sh -e ${ACCOUNT_NAME} ${PROJECT_ID} ${SUBSCRIPTION_NAME} ${SERVICE_ACCOUNT_KEY})

disable-fake-oauth: ## Disables fake oauth in spinnaker
	sh 3.1-fake_oauth.sh -d
	
delete-spinnaker: ## Deletes the spinnaker instance in k3s
	sh 3-spinnaker.sh -s
	$(call multipassExec,./3-spinnaker.sh -d)

port-forward: ## Port forwards spinnaker
	sh 3-spinnaker.sh -f

stop-port-forward: ## Stops spinnaker port fowarding
	sh 3-spinnaker.sh -s

override-%: ## Override the generic target. Requieres IMAGE environment variable.
	$(call multipassExec,./3.2-override_services.sh $* ${IMAGE})

clean-up: ## Deletes the multipass vm and everything inside.
	sh 99-clean_up.sh

define multipassExec
	multipass exec k3s-spin -- sh -c "cd /home/spin && sudo $1"
endef