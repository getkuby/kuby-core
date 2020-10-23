#! /bin/bash

function setup_cluster() {
  echo travis_fold:start:setup_cluster

  set -o xtrace

  # install kubeadm and use it to set up the cluster
  sudo apt-get update
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl
  sudo kubeadm init

  # copy kubeconfig to default location so kubectl works
  mkdir -p ~/.kube
  sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
  sudo chown $(id -u):$(id -g) ~/.kube/config

  # allow pods to be scheduled on the master node
  kubectl taint nodes --all node-role.kubernetes.io/master-
  set +o xtrace

  echo travis_fold:end:setup_cluster
}

function setup_node() {
  set +o xtrace
  source ~/.nvm/nvm.sh

  echo travis_fold:start:setup_node

  set -o xtrace
  nvm install 15.0.1
  nvm use 15.0.1
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update && sudo apt-get install -y yarn
  set +o xtrace

  echo travis_fold:end:setup_node
}
