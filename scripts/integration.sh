#! /bin/bash

K8S_VERSION='1.19.11'

kind create cluster --name kuby-test --image kindest/node:v$K8S_VERSION

# clone rails app
gem install prebundler -v '< 1'
git clone --depth=1 https://github.com/getkuby/kuby_test.git
cp -r kuby-core/ kuby_test/vendor/
cd kuby_test
printf "\ngem 'kuby-core', path: 'vendor/kuby-core'\n" >> Gemfile
printf "\ngem 'kuby-prebundler', '~> 0.1'\n" >> Gemfile
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
cat <<'EOF' > kuby.rb
class VendorPhase < Kuby::Docker::Layer
  def apply_to(dockerfile)
    dockerfile.copy('vendor/kuby-core', 'vendor/kuby-core')
  end
end

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

Kuby.define('Kubyapp') do
  environment(:production) do
    docker do
      image_url 'localhost:5000/kubyapp'

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
        tls_enabled false

        database do
          user 'kubyapp'
          password 'password'
        end
      end

      provider :bare_metal do
        storage_class 'standard'
      end
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
mkdir app/views/home/
touch app/views/home/index.html.erb

kubectl=$(bundle show kubectl-rb)/vendor/kubectl

# start docker registry (helps make sure pushes work)
docker run -d -p 5000:5000 --name registry registry:2

# build and push
GLI_DEBUG=true bundle exec kuby -e production build \
  -a PREBUNDLER_ACCESS_KEY_ID=${PREBUNDLER_ACCESS_KEY_ID} \
  -a PREBUNDLER_SECRET_ACCESS_KEY=${PREBUNDLER_SECRET_ACCESS_KEY}
GLI_DEBUG=true bundle exec kuby -e production push

docker images | grep kubyapp | grep -v latest | tr -s ' ' | cut -d' ' -f 2 | while read tag; do
  kind load docker-image localhost:5000/kubyapp:$tag --name kuby-test
done

# setup cluster
GLI_DEBUG=true bundle exec kuby -e production setup
# force nginx ingress to be a nodeport since we don't have any load balancers
$kubectl -n ingress-nginx patch svc ingress-nginx -p '{"spec":{"type":"NodePort"}}'

# deploy!
GLI_DEBUG=true bundle exec kuby -e production deploy || true

while [[ "$($kubectl -n kubyapp-production get po kubyapp-web-mysql-0 -o json | jq -r .status.phase)" != "Running" ]]; do
  echo "Waiting for MySQL pod to start..."
  sleep 5
done

# Do this three times in case the db doesn't start in time and the deploy fails.
# This can happen even after waiting for the pod to start above, not sure why.
GLI_DEBUG=true bundle exec kuby -e production deploy ||
  GLI_DEBUG=true bundle exec kuby -e production deploy ||
  GLI_DEBUG=true bundle exec kuby -e production deploy

# in KIND clusters, configuring ingress-nginx is a huge PITA, so we just port-forward
# to the ingress service instead
$kubectl -n ingress-nginx port-forward svc/ingress-nginx 5555:80 &

# wait for port forwarding
timeout 10 vendor/kuby-core/scripts/wait-for-ingress.sh

# attempt to hit the app
curl -vvv localhost:5555 \
  -H "Host: localhost"\
  --fail \
  --connect-timeout 5 \
  --max-time 10 \
  --retry 5 \
  --retry-max-time 40 || exit $?

# execute remote command
GLI_DEBUG=true bundle exec kuby -e production remote exec "bundle exec rails runner 'puts \"Hello from Kuby\"'" | grep "Hello from Kuby"
