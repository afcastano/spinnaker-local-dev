Local development environment for Spinnaker services
=====================================================

**WORK IN PROGRESS**


*Based on: https://github.com/pndurette/spinnaker-playground*

> **TL:DR;** Set up your MAC to quickly test any modification to Spinnaker Code.  


It Involves:
- Installing a k3s cluster in a [Multipass](https://multipass.run/) instance.
- Installing a [fake-oauth2 server](https://github.com/patientsknowbest/fake-oauth2-server) for [Spinnaker](https://www.spinnaker.io/) authentication.
- Installing a docker registry to push your [Spinnaker](https://www.spinnaker.io/) modified images.
- Install [Spinnaker](https://www.spinnaker.io/) using the new images you modified and defaulting to the public ones.

Dependencies:  
- Docker
- [Multipass](https://multipass.run/)

**Steps**

1. Install [Multipass](https://multipass.run/).
```
brew cask install multipass
```
2. Run `make` for the available options.

Pending
===========
- Run fake oauth server.
- Install and configure local docker registry
- Configure custom roles and users for testing.
- Automaticaly use custom images pushed to the local registry

