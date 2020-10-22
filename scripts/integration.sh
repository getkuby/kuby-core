#! /bin/bash

function setup_cluster() {
  echo travis_fold:start:setup_cluster

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

  echo travis_fold:end:setup_cluster
}
