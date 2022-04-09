#! /bin/bash

# clone rails app
gem install prebundler -v '< 1'
git clone https://github.com/getkuby/kuby_test.git
cp -r kuby-core/ kuby_test/vendor/
cd kuby_test
git fetch origin crdb
git checkout crdb
printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
printf "gem 'kuby-prebundler', '~> 0.1'\n" >> Gemfile
printf "gem 'kuby-kind', '~> 0.2'\n" >> Gemfile
printf "gem 'kuby-crdb', github: 'getkuby/kuby-crdb'\n" >> Gemfile
printf "gem 'kube-dsl', github: 'getkuby/kube-dsl'\n" >> Gemfile
printf "gem 'kuby-cert-manager', github: 'getkuby/kuby-cert-manager'\n" >> Gemfile
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
    bucket: 'prebundler',
    region: 'us-east-1'
  )
end
EOF
prebundle install --jobs 2 --retry 3 --no-binstubs
yarn install
bundle exec bin/rails g kuby
cat <<EOF > kuby.rb
class VendorPhase < Kuby::Docker::Layer
  def apply_to(dockerfile)
    dockerfile.copy('vendor/kuby-core', 'vendor/kuby-core')
  end
end

require 'kuby/kind'
require 'kuby/prebundler'
require 'active_support/core_ext'
require 'active_support/encrypted_configuration'

# keep this in here to make sure RAILS_MASTER_KEY is being provided somehow
app_creds = ActiveSupport::EncryptedConfiguration.new(
  config_path: File.join('config', 'credentials.yml.enc'),
  key_path: File.join('config', 'master.key'),
  env_key: 'RAILS_MASTER_KEY',
  raise_if_missing_key: true
)

Kuby.define('Kubytest') do
  environment(:production) do
    docker do
      image_url 'localhost:5000/kubytest'

      credentials do
        username "foobar"
        password "foobar"
        email "foo@bar.com"
      end

      # have to insert after setup phase b/c prebundler replaces the existing bundler phase
      insert :vendor_phase, VendorPhase.new(environment), after: :setup_phase
    end

    kubernetes do
      add_plugin :prebundler

      add_plugin :rails_app do
        tls_enabled true
        hostname 'kubytest.io'
      end

      configure_plugin(:cert_manager) do
        skip_tls_verify true
        server_url 'https://pebble.pebble:14000/dir'
      end

      provider :kind do
        use_kubernetes_version '${K8S_VERSION}'
      end
    end
  end
end
EOF
cat <<'EOF' > config/database.yml
default: &default
  adapter: cockroachdb
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: localhost
development:
  <<: *default
  database: kubytest_development
production:
  <<: *default
  database: kubytest_production
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
mkdir app/views/home/
touch app/views/home/index.html.erb

# start docker registry (helps make sure pushes work)
docker run -d -p 5000:5000 --name registry registry:2

# build and push
GLI_DEBUG=true bundle exec kuby -e production build \
  -a PREBUNDLER_ACCESS_KEY_ID=${PREBUNDLER_ACCESS_KEY_ID} \
  -a PREBUNDLER_SECRET_ACCESS_KEY=${PREBUNDLER_SECRET_ACCESS_KEY}
GLI_DEBUG=true bundle exec kuby -e production push

# setup cluster
GLI_DEBUG=true bundle exec kuby -e production setup

# find kubectl executable
kubectl=$(bundle show kubectl-rb)/vendor/kubectl

# export kubeconfig
kind get kubeconfig --name kubytest > .kubeconfig
export KUBECONFIG=.kubeconfig

# find ingress IP
ingress_ip=$($kubectl -n ingress-nginx get svc ingress-nginx-controller -o json | jq -r .spec.clusterIP)

# modification to the coredns config that resolves kubytest.io to the ingress IP
corefile_mod=$(cat <<END
kubytest.io {
  hosts {
    $ingress_ip kubytest.io
    fallthrough
  }
  whoami
}
END
)

# modify the coredns config (lives in Corefile) and restart the deployment
$kubectl -n kube-system get configmap coredns -o json \
  | jq -r ".data.Corefile |= . + \"$corefile_mod\"" \
  | $kubectl apply -f -
$kubectl -n kube-system rollout restart deployment coredns
$kubectl -n kube-system wait --for=condition=available --timeout=30s deployment/coredns

# create pebble server (issues fake TLS certs) and get the root and intermediate certs
$kubectl apply -f vendor/kuby-core/scripts/pebble.yaml
$kubectl -n pebble wait --for=condition=available --timeout=30s deployment/pebble
$kubectl -n pebble port-forward deployment/pebble 15000:15000 &
sleep 2
curl -f -vvv -ksS https://localhost:15000/intermediates/0 > pebble.intermediate.crt
curl -f -vvv -ksS https://localhost:15000/roots/0 > pebble.root.crt

# deploy!
GLI_DEBUG=true bundle exec kuby -e production deploy

# attempt to hit the app
curl -vvv https://kubytest.io \
  --resolve kubytest.io:443:127.0.0.1 \
  --cacert pebble.root.crt \
  --fail \
  --connect-timeout 5 \
  --max-time 10 \
  --retry 5 \
  --retry-max-time 40

# execute remote command
GLI_DEBUG=true bundle exec kuby -e production remote exec \
  "bundle exec rails runner 'puts \"Hello from Kuby\"'" \
  | grep "Hello from Kuby"
