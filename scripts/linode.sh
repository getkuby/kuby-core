#! /bin/bash

# preflight
set -ev
swapoff -a

# install packages
sudo apt-get update
sudo apt-get install -y git curl autoconf bison build-essential \
  libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev \
  libffi-dev libgdbm6 libgdbm-dev libdb-dev docker.io \
  default-libmysqlclient-dev

# set up asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0
source $HOME/.asdf/asdf.sh

# install ruby and node runtimes
asdf plugin add ruby
asdf plugin add nodejs
asdf install ruby 2.6.6
bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
asdf install nodejs 14.13.0
printf "ruby 2.6.6\n" >> ./.tool-versions
printf "nodejs 14.13.0\n" >> ./.tool-versions

# install kubeadm and use it to set up the cluster
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
# add hostpath storage class so assets etc work
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: "192.168.0.0/16"
controllerManager:
  extraArgs:
    enable-hostpath-provisioner: "true"
EOF
sudo kubeadm init --config ./kubeadm-config.yaml

# copy kubeconfig to default location so kubectl works
mkdir -p ~/.kube
cp -i /etc/kubernetes/admin.conf ~/.kube/config
chown $(id -u):$(id -g) ~/.kube/config

# start up the calico CNI
# this sed hack is necessary because of https://github.com/tigera/operator/issues/992
curl -Ns https://docs.projectcalico.org/manifests/tigera-operator.yaml | \
  sed 's/v1.10.8/1.10.8/g' | \
  kubectl create -f -
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# make hostpath storage class available
echo <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
 namespace: kube-system
 name: hostpath
 annotations:
   storageclass.beta.kubernetes.io/is-default-class: "true"
 labels:
   addonmanager.kubernetes.io/mode: EnsureExists
provisioner: kubernetes.io/host-path
EOF

# allow pods to be scheduled on the master node
kubectl taint nodes --all node-role.kubernetes.io/master-

# generate rails app
gem install rails -v 6.0.3.4
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn
rails _6.0.3.4_ new kubyapp -d mysql
cd kubyapp
printf "\ngem 'kuby-core', github: 'getkuby/kuby-core', branch: 'kubeadm'\n" >> Gemfile
printf "\ngem 'docker-remote', github: 'getkuby/docker-remote', branch: 'debug'\n" >> Gemfile
printf "\ngem 'kuby-kube-db', github: 'getkuby/kuby-kube-db', branch: 'debug'\n" >> Gemfile
bundle install
bundle exec rails g kuby
rm kuby.rb
cat <<EOF | sudo tee kuby.rb
Kuby.define('Kubyapp') do
  environment(:production) do
    docker do
      insert(:vendor, before: :bundler_phase) do |dockerfile|
        dockerfile.copy('vendor', 'vendor')
      end

      image_url 'localhost:5000/kubyapp'
    end

    kubernetes do
      add_plugin :rails_app do
        tls_enabled false

        database do
          user 'kubyapp'
          password 'password'
        end

        app_secrets do
          data do
            add 'KUBYAPP_DATABASE_PASSWORD', 'password'
          end
        end
      end

      provider :docker_desktop
    end
  end
end
EOF

# start docker registry
docker run -d -p 5000:5000 --name registry registry:2

# build and push
GLI_DEBUG=true bundle exec kuby -e production build
GLI_DEBUG=true bundle exec kuby -e production push

# setup cluster
GLI_DEBUG=true bundle exec kuby -e production setup

# deploy!
GLI_DEBUG=true bundle exec kuby -e production deploy

# attempt to hit the app
curl kubyapp-web:8080
