#!/bin/bash
set -ex
source .ci/common
arch=`uname -m`
if [[ $arch == 'x86_64' ]]
then
        arch="amd64"
else
        arch="arm64"
fi

K8S_VERSION=1.23.1
MINIKUBE_VERSION=1.25.2
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/${arch}/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
sudo apt update && sudo apt install -y conntrack
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-linux-${arch} && chmod +x minikube && sudo mv minikube /usr/local/bin/
mkdir -p $HOME/.kube $HOME/.minikube
touch $KUBECONFIG
sudo systemctl enable docker.service
sudo minikube start --profile=minikube --vm-driver=none --kubernetes-version=v${K8S_VERSION}
# sudo minikube start
minikube update-context --profile=minikube
eval "$(minikube docker-env --profile=minikube)" && export DOCKER_CLI='docker'

curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm upgrade --wait \
  -n kube-system -i rawfile-csi \
  --set serviceMonitor.enabled=false \
  --set controller.image.repository=$CI_IMAGE_REPO --set controller.image.tag=$CI_TAG \
  --set node.image.repository=$CI_IMAGE_REPO --set node.image.tag=$CI_TAG \
  ./deploy/charts/rawfile-csi/
