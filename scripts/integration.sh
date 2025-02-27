#! /bin/bash

set -e

# clone rails app
gem install prebundler -v '< 1'
git clone https://github.com/getkuby/kuby_test.git
cp -r kuby-core/ kuby_test/vendor/
cd kuby_test

# remove sorbet annotations
gem install curdle
curdle $(find vendor/kuby-core/lib -name '*.rb') > /dev/null

# gems
printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
printf "gem 'kuby-prebundler', '~> 0.1'\n" >> Gemfile
printf "gem 'kuby-kind', '~> 0.2'\n" >> Gemfile
printf "gem 'kuby-sidekiq', '~> 0.3'\n" >> Gemfile
printf "gem 'sidekiq', '~> 6.5'\n" >> Gemfile

# install ruby deps
bundle lock
cat <<'EOF' > .prebundle_config
Prebundler.configure do |config|
  config.storage_backend = Prebundler::S3Backend.new(
    client: Aws::S3::Client.new(
      region: 'default',
      credentials: Aws::Credentials.new(
        ENV['PREBUNDLER_ACCESS_KEY_ID'],
        ENV['PREBUNDLER_SECRET_ACCESS_KEY']
      ),
      endpoint: 'https://us-east-1.linodeobjects.com',
      http_continue_timeout: 0
    ),
    bucket: 'prebundler2',
    region: 'us-east-1'
  )
end
EOF
prebundle install --jobs 2 --retry 3 --no-binstubs

# # javascript deps, cxx flags because node-sass is a special snowflake
# CXXFLAGS="--std=c++17" yarn install

# # bootstrap app for use with kuby
# bundle exec bin/rails g kuby
# cat <<EOF > kuby.rb
# class VendorPhase < Kuby::Docker::Layer
#   def apply_to(dockerfile)
#     dockerfile.copy('vendor/kuby-core', 'vendor/kuby-core')
#   end
# end

# require 'kuby/kind'
# require 'kuby/sidekiq'
# require 'kuby/prebundler'
# require 'active_support/core_ext'
# require 'active_support/encrypted_configuration'

# # keep this in here to make sure RAILS_MASTER_KEY is being provided somehow
# app_creds = ActiveSupport::EncryptedConfiguration.new(
#   config_path: File.join('config', 'credentials.yml.enc'),
#   key_path: File.join('config', 'master.key'),
#   env_key: 'RAILS_MASTER_KEY',
#   raise_if_missing_key: true
# )

# Kuby.define('Kubytest') do
#   environment(:production) do
#     docker do
#       image_url 'localhost:5000/kubytest'

#       credentials do
#         username "foobar"
#         password "foobar"
#         email "foo@bar.com"
#       end

#       # have to insert after setup phase b/c prebundler replaces the existing bundler phase
#       insert :vendor_phase, VendorPhase.new(environment), after: :setup_phase
#     end

#     kubernetes do
#       add_plugin :prebundler

#       add_plugin :rails_app do
#         tls_enabled true
#         hostname 'kubytest.io'
#       end

#       configure_plugin(:cert_manager) do
#         skip_tls_verify true
#         server_url 'https://pebble.pebble:14000/dir'
#       end

#       add_plugin :sidekiq do
#         replicas 2
#       end

#       provider :kind do
#         use_kubernetes_version '${K8S_VERSION}'
#       end
#     end
#   end
# end
# EOF
# cat <<'EOF' > config/database.yml
# default: &default
#   adapter: cockroachdb
#   pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
#   host: localhost
# development:
#   <<: *default
#   database: kubytest_development
# production:
#   <<: *default
#   database: kubytest_production
# EOF
# cat <<'EOF' > config/routes.rb
# Rails.application.routes.draw do
#   root to: 'home#index'
# end
# EOF
# cat <<'EOF' > app/controllers/home_controller.rb
# class HomeController < ApplicationController
#   def index
#   end
# end
# EOF
# cat <<'EOF' > app/models/widget.rb
# class Widget < ApplicationRecord
# end
# EOF
# mkdir -p app/sidekiq
# cat <<'EOF' > app/sidekiq/widgets_job.rb
# class WidgetsJob
#   include Sidekiq::Job

#   def perform(id)
#     widget = Widget.find(id)
#     widget.update(status: 'processed')
#   end
# end
# EOF
# cat <<'EOF' > config/initializers/sidekiq.rb
# if Rails.env.production?
#   require 'kuby'

#   Kuby.load!

#   Sidekiq.configure_server do |config|
#     config.redis = Kuby.environment.kubernetes.plugin(:sidekiq).connection_params
#   end

#   Sidekiq.configure_client do |config|
#     config.redis = Kuby.environment.kubernetes.plugin(:sidekiq).connection_params
#   end
# end
# EOF
# mkdir -p db/migrate
# cat <<'EOF' > db/migrate/20220423211801_create_widgets.rb
# class CreateWidgets < ActiveRecord::Migration[6.0]
#   def change
#     create_table :widgets do |t|
#       t.string :status, default: 'pending'
#       t.timestamps
#     end
#   end
# end
# EOF
# mkdir app/views/home/
# touch app/views/home/index.html.erb

# # start docker registry (helps make sure pushes work)
# docker run -d -p 5000:5000 --name registry registry:2

# # build and push
# GLI_DEBUG=true bundle exec kuby -e production build \
#   -a PREBUNDLER_ACCESS_KEY_ID=${PREBUNDLER_ACCESS_KEY_ID} \
#   -a PREBUNDLER_SECRET_ACCESS_KEY=${PREBUNDLER_SECRET_ACCESS_KEY}
# GLI_DEBUG=true bundle exec kuby -e production push

# # setup cluster
# GLI_DEBUG=true bundle exec kuby -e production setup
# GLI_DEBUG=true bundle exec kuby -e production setup

# # find kubectl executable
# kubectl=$(bundle show kubectl-rb)/vendor/kubectl

# # export kubeconfig
# kind get kubeconfig --name kubytest > .kubeconfig
# export KUBECONFIG=.kubeconfig

# # find ingress IP
# ingress_ip=$($kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r .spec.clusterIP)

# # modification to the coredns config that resolves kubytest.io to the ingress IP
# corefile_mod=$(cat <<END
# kubytest.io {
#   hosts {
#     $ingress_ip kubytest.io
#     fallthrough
#   }
#   whoami
# }
# END
# )

# # modify the coredns config (lives in Corefile) and restart the deployment
# $kubectl -n kube-system get configmap coredns -o json \
#   | jq -r ".data.Corefile |= . + \"$corefile_mod\"" \
#   | $kubectl apply -f -
# $kubectl -n kube-system rollout restart deployment coredns
# $kubectl -n kube-system wait --for=condition=available --timeout=120s deployment/coredns

# # create pebble server (issues fake TLS certs) and get the root and intermediate certs
# $kubectl apply -f vendor/kuby-core/scripts/pebble.yaml
# $kubectl -n pebble wait --for=condition=available --timeout=30s deployment/pebble
# $kubectl -n pebble port-forward deployment/pebble 15000:15000 &
# sleep 2
# curl -f -vvv -ksS https://localhost:15000/intermediates/0 > pebble.intermediate.crt
# curl -f -vvv -ksS https://localhost:15000/roots/0 > pebble.root.crt

# # deploy!
# GLI_DEBUG=true bundle exec kuby -e production deploy

# # wait for pebble to issue the certificate
# while [[ "$($kubectl -n kubytest-production get order -o json | jq -r '.items[0].status.state')" != "valid" ]]; do
#   echo "Waiting for certificate to be issued..."
#   sleep 5
# done

# # verify certificate chain
# $kubectl -n kubytest-production get secret kubytest-tls -o json \
#   | jq -r '.data["tls.crt"]' \
#   | base64 -d - \
#   | openssl verify -CAfile pebble.root.crt -untrusted pebble.intermediate.crt

# # attempt to hit the app
# curl -vvv https://kubytest.io \
#   --resolve kubytest.io:443:127.0.0.1 \
#   --cacert pebble.root.crt \
#   --fail \
#   --connect-timeout 5 \
#   --max-time 10 \
#   --retry 5 \
#   --retry-max-time 40

# # insert job
# GLI_DEBUG=true bundle exec kuby -e production remote exec \
#   "bundle exec rails runner 'w = Widget.create(status: \"pending\"); WidgetsJob.perform_async(w.id)'"

# GLI_DEBUG=true bundle exec kuby -e production remote exec \
#   "bundle exec rails runner 'w = Widget.first; puts w.status'" \
#   | grep 'processed'
