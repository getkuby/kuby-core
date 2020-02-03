module Kuby
  module Kubernetes
    class ProviderError < StandardError; end

    class Spec
      extend ValueFields

      WEB_ROLE = 'web'.freeze
      DEFAULT_ENVIRONMENT = 'production'.freeze
      MASTER_KEY_VAR = 'RAILS_MASTER_KEY'.freeze
      ENV_SECRETS = [MASTER_KEY_VAR].freeze
      ENV_EXCLUDE = ['RAILS_ENV'].freeze

      attr_reader :definition
      value_field :environment, default: DEFAULT_ENVIRONMENT
      value_fields :hostname

      def initialize(definition)
        @definition = definition
      end

      def provider(provider_name = nil, &block)
        if provider_name
          if @provider || provider_klass = Kuby.providers[provider_name]
            @provider ||= provider_klass.new(definition)
            @provider.configure(&block)
          else
            msg = if provider_name
              "no provider registered with name #{provider_name}, "\
                'do you need to add a gem to your Gemfile?'
            else
              'no provider configured'
            end

            raise ProviderError, msg
          end
        end

        @provider
      end

      def namespace(&block)
        spec = self

        @namespace ||= Namespace.new do
          name "#{spec.selector_app}-#{spec.environment}"
        end

        @namespace.instance_eval(&block) if block
        @namespace
      end

      def service(&block)
        spec = self

        @service ||= Service.new do
          name "#{spec.selector_app}-svc"
          namespace spec.namespace.name
          type 'ClusterIP'

          port do
            name 'http'
            port 8080
            protocol 'TCP'
            target_port 'http'
          end

          labels do
            app spec.selector_app
            role spec.role
          end

          selector do
            app spec.selector_app
            role spec.role
          end
        end

        @service.instance_eval(&block) if block
        @service
      end

      def service_account(&block)
        spec = self

        @service_account ||= ServiceAccount.new do
          name "#{spec.selector_app}-sa"
          namespace spec.namespace.name

          labels do
            app spec.selector_app
            role spec.role
          end
        end

        @service_account.instance_eval(&block) if block
        @service_account
      end

      def config_map(&block)
        spec = self

        @config_map ||= ConfigMap.new do
          name "#{spec.selector_app}-config"
          namespace spec.namespace.name

          ENV.each_pair do |key, val|
            include_key = key.start_with?('RAILS_') &&
              !ENV_SECRETS.include?(key) &&
              !ENV_EXCLUDE.include?(key)

            if include_key
              send(key.to_sym, val)
            end
          end
        end

        @config_map.instance_eval(&block) if block
        @config_map
      end

      def app_secrets(&block)
        spec = self

        @app_secrets ||= Secrets.new do
          type 'Opaque'
          name "#{spec.selector_app}-secrets"
          namespace spec.namespace.name

          if master_key = ENV[MASTER_KEY_VAR]
            send MASTER_KEY_VAR.to_sym, master_key
          else
            master_key_path = spec.app.root.join('config', 'master.key')

            if master_key_path.exist?
              send MASTER_KEY_VAR.to_sym, File.read(master_key_path).strip
            end
          end
        end

        @app_secrets.instance_eval(&block) if block
        @app_secrets
      end

      def registry_secret(&block)
        spec = self

        @registry_secret ||= RegistrySecret.new do
          name "#{spec.selector_app}-registry-secret"
          namespace spec.namespace.name

          docker_config do
            registry_host spec.docker.metadata.image_host
            username spec.docker.credentials.username
            password spec.docker.credentials.password
            email spec.docker.credentials.email
          end
        end

        @registry_secret.instance_eval(&block) if block
        @registry_secret
      end

      def deployment(&block)
        kube_spec = self

        @deployment ||= Deployment.new do
          name "#{kube_spec.selector_app}-deployment"
          namespace kube_spec.namespace.name

          labels do
            app kube_spec.selector_app
            role kube_spec.role
          end

          selector do
            app kube_spec.selector_app
            role kube_spec.role
          end

          strategy do
            type 'RollingUpdate'

            rolling_update do
              max_surge '25%'
              max_unavailable 0
            end
          end

          template do
            labels do
              app kube_spec.selector_app
              role kube_spec.role
            end

            spec do
              container do
                name "#{kube_spec.selector_app}-#{kube_spec.role}"
                image kube_spec.image_url_with_tag
                image_pull_policy 'IfNotPresent'

                port do
                  container_port kube_spec.docker.webserver_phase.port
                  name 'http'
                  protocol 'TCP'
                end

                env_from do
                  config_map_ref do
                    name kube_spec.config_map.name
                  end
                end

                env_from do
                  secret_ref do
                    name kube_spec.app_secrets.name
                  end
                end

                readiness_probe do
                  success_threshold 1
                  failure_threshold 2
                  initial_delay_seconds 15
                  period_seconds 3
                  timeout_seconds 1

                  http_get do
                    path '/healthz'
                    port kube_spec.docker.webserver_phase.port
                    scheme 'HTTP'
                  end
                end
              end

              image_pull_secret do
                name kube_spec.registry_secret.name
              end

              restart_policy 'Always'
              service_account_name kube_spec.service_account.name
            end
          end
        end

        @deployment.instance_eval(&block) if block
        @deployment
      end

      def ingress(&block)
        spec = self

        @ingress ||= Ingress.new do
          name "#{spec.selector_app}-ingress"
          namespace spec.namespace.name

          rule do
            host spec.hostname

            http do
              path do
                backend do
                  service_name spec.service.name
                  service_port spec.service.ports.first.port
                end
              end
            end
          end
        end

        @ingress.instance_eval(&block) if block
        @ingress
      end

      def resources
        @resources ||= [
          namespace,
          service,
          service_account,
          config_map,
          app_secrets,
          registry_secret,
          deployment,
          ingress
        ]
      end

      def selector_app
        @selector_app ||= definition.app_name.downcase
      end

      def role
        WEB_ROLE
      end

      def image_url_with_tag
        @image_url ||= begin
          tag = docker.latest_tags.find do |tag|
            tag != 'latest'
          end

          "#{docker.metadata.image_url}:#{tag}"
        end
      end

      def docker
        definition.docker
      end

      def app
        definition.app
      end
    end
  end
end
