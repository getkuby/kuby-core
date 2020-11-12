#! /bin/bash

# preflight
set -ev
unset BUNDLE_GEMFILE

echo travis_fold:start:setup_cluster
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl jq
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
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# start up the calico CNI
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml
# make hostpath storage class available
cat <<'EOF' | kubectl apply -f -
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
echo travis_fold:end:setup_cluster

# setup nvm/node
echo travis_fold:start:setup_node
source ~/.nvm/nvm.sh
nvm install 14.13.0
nvm use 14.13.0
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn
echo travis_fold:end:setup_node

# generate rails app
echo travis_fold:start:generate_app
gem install rails -v 6.0.3.4 --no-document
cd ..
rails _6.0.3.4_ new kubyapp -d mysql
cd kubyapp
printf "\ngem 'kuby-core', github: 'getkuby/kuby-core', branch: 'kubeadm'\n" >> Gemfile
printf "gem 'docker-remote', github: 'getkuby/docker-remote', branch: 'debug'\n" >> Gemfile
printf "gem 'kuby-kube-db', github: 'getkuby/kuby-kube-db', branch: 'debug'\n" >> Gemfile
bundle install
bundle exec rails g kuby
cat <<'EOF' > kuby.rb
Kuby.define('Kubyapp') do
  environment(:production) do
    docker do
      insert(:vendor, before: :bundler_phase) do |dockerfile|
        dockerfile.copy('vendor', 'vendor')
      end

      insert :prebundler_phase, before: :bundler_phase do |dockerfile|
        dockerfile.run('gem install prebundler')
        dockerfile.copy('./.prebundle_config', './')
      end

      bundler_phase.executable = 'prebundle'

      image_url 'localhost:5000/kubyapp'
    end

    kubernetes do
      add_plugin :rails_app do
        tls_enabled false

        database do
          user 'kubyapp'
          password 'password'
        end
      end

      provider :bare_metal
    end
  end
end
EOF
cat <<'EOF' > config/database.yml
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: password
  host: localhost
development:
  <<: *default
  database: kubyapp_development
production:
  <<: *default
  database: kubyapp_production
EOF
cat <<'EOF' > config/routes.rb
Rails.application.routes.draw do
  root to: 'home#index'
end
EOF
cat <<'EOF' > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
  end
end
EOF
cat <<"EOF" > .prebundle_config
require 'aws-sdk'

Prebundler.configure do |config|
  config.storage_backend = Prebundler::S3Backend.new(
    client: Aws::S3::Client.new(
      region: 'default',
      credentials: Aws::Credentials.new('${PREBUNDLER_LINODE_ACCESS_KEY_ID}', '${PREBUNDLER_LINODE_SECRET_ACCESS_KEY}'),
      endpoint: 'https://us-east-1.linodeobjects.com',
      http_continue_timeout: 0
    ),
    bucket: 'kuby-prebundle',
    region: 'us-east-1'
  )
end
EOF
mkdir app/views/home/
touch app/views/home/index.html.erb
echo travis_fold:end:generate_app

# start docker registry
echo travis_fold:start:start_registry
docker run -d -p 5000:5000 --name registry registry:2
echo travis_fold:end:start_registry

# build and push
echo travis_fold:start:build_and_push
GLI_DEBUG=true bundle exec kuby -e production build
GLI_DEBUG=true bundle exec kuby -e production push
echo travis_fold:end:build_and_push

# setup cluster
echo travis_fold:start:setup
GLI_DEBUG=true bundle exec kuby -e production setup
# force nginx ingress to be a nodeport since we don't have any load balancers
kubectl -n ingress-nginx patch svc ingress-nginx -p '{"spec":{"type":"NodePort"}}'
echo travis_fold:end:setup

# deploy!
echo travis_fold:start:deploy
GLI_DEBUG=true bundle exec kuby -e production deploy || \
  GLI_DEBUG=true bundle exec kuby -e production deploy
echo travis_fold:end:deploy

# get ingress IP from kubectl; attempt to hit the app
ingress_ip=$(kubectl -n ingress-nginx get svc ingress-nginx -o json | jq -r .spec.clusterIP)
curl -vvv $ingress_ip:80 -H "Host: localhost" --fail
