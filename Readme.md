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
- Helm

**Steps**

1. Install [Multipass](https://multipass.run/).
```
brew cask install multipass
```
2. Run `1-install_k3s.sh` to install k3s in Multipass and configure spinnaker there.

Pending
===========
- Install docker registry in k3s https://itnext.io/setup-a-private-registry-on-k3s-f30404f8e4d3
- Enable insecure registry support: https://github.com/rancher/k3s/issues/145
- Push fake-oauth to docker registry
- deploy fake-oauth to k3s
- configure spinnaker to use fake oauth

- Check override base url for auth to work in spinnaker: https://www.spinnaker.io/setup/quickstart/faq/#i-want-to-expose-localdebian-spinnaker-on-a-public-ip-address-but-it-always-binds-to-localhost

- Local roles: 
https://kb.armory.io/troubleshooting/file-based-authorization/

- Custom images:
https://medium.com/@sergiipikhterev/creating-custom-docker-images-for-spinnaker-components-f2e41e13db1a
