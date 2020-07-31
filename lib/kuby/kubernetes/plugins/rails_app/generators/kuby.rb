require 'rails/generators'
require 'rails/generators/base'

class KubyGenerator < Rails::Generators::Base
  def create_initializer_file
    initializer(
      'kuby.rb',
      <<~END
        # Define a production Kuby deploy environment
        Kuby.define(:production) do
          docker do
            # Configure your Docker registry credentials here. Add them to your
            # Rails credentials file by running `bundle exec rake credentials:edit`.
            credentials do
              username Rails.application.credentials[:KUBY_DOCKER_USERNAME]
              password Rails.application.credentials[:KUBY_DOCKER_PASSWORD]
              email Rails.application.credentials[:KUBY_DOCKER_EMAIL]
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

            # Use minikube as the default provider.
            # See: https://github.com/kubernetes/minikube
            #
            # Note: you will likely want to use a different provider when deploying
            # your application into a production environment. To configure a different
            # provider, add the corresponding gem to your gemfile and update the
            # following line according to the provider gem's README.
            provider :minikube
          end
        end
      END
    )
  end
end
