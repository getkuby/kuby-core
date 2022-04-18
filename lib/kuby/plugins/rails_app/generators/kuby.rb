# typed: false

require 'rails/generators'
require 'rails/generators/base'

class KubyGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file(
      File.join(*%w(config initializers kuby.rb)),
      <<~END
        require 'kuby'
        Kuby.load!
      END
    )
  end

  def create_config_file
    create_file(
      'kuby.rb',
      <<~END
        require 'active_support/core_ext'
        require 'active_support/encrypted_configuration'

        # Define a production Kuby deploy environment
        Kuby.define('#{app_name}') do
          environment(:production) do
            # Because the Rails environment isn't always loaded when
            # your Kuby config is loaded, provide access to Rails
            # credentials manually.
            app_creds = ActiveSupport::EncryptedConfiguration.new(
              config_path: File.join('config', 'credentials.yml.enc'),
              key_path: File.join('config', 'master.key'),
              env_key: 'RAILS_MASTER_KEY',
              raise_if_missing_key: true
            )

            docker do
              # Configure your Docker registry credentials here. Add them to your
              # Rails credentials file by running `bundle exec rake credentials:edit`.
              credentials do
                username app_creds[:KUBY_DOCKER_USERNAME]
                password app_creds[:KUBY_DOCKER_PASSWORD]
                email app_creds[:KUBY_DOCKER_EMAIL]
              end

              # Configure the URL to your Docker image here, eg:
              # image_url 'foo.bar.com/me/myproject'
              #
              # If you're using Gitlab's Docker registry, try something like this:
              # image_url 'registry.gitlab.com/<username>/<repo>'
            end

            kubernetes do
              # Add a plugin that facilitates deploying a Rails app.
              add_plugin :rails_app

              # Use Docker Desktop as the provider.
              # See: https://www.docker.com/products/docker-desktop
              #
              # Note: you will likely want to use a different provider when deploying
              # your application into a production environment. To configure a different
              # provider, add the corresponding gem to your gemfile and update the
              # following line according to the provider gem's README.
              provider :docker_desktop
            end
          end
        end
      END
    )
  end

  def create_dockerignore
    create_file(
      '.dockerignore',
      <<~END
        .git/

        # Ignore bundler config.
        .bundle

        # Ignore all logfiles and tempfiles.
        log/*
        tmp/*
        !log/.keep
        !tmp/.keep

        # Ignore pidfiles, but keep the directory.
        tmp/pids/*
        !tmp/pids/
        !tmp/pids/.keep

        # Ignore uploaded files in development.
        storage/*
        !storage/.keep

        public/assets
        **/.byebug_history

        # Ignore master key for decrypting credentials and more.
        config/master.key

        public/packs
        public/packs-test
        node_modules
        yarn-error.log
        **/yarn-debug.log*
        **/.yarn-integrity
      END
    )
  end

  private

  def app_name
    @app_name ||= begin
      app_class = Rails.application.class

      if app_class.respond_to?(:module_parent_name)
        app_class.module_parent_name
      else
        app_class.parent_name
      end
    end
  end
end
