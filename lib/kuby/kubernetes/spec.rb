module Kuby
  module Kubernetes
    class Spec
      extend ValueFields

      WEB_ROLE = 'web'.freeze
      DEFAULT_ENVIRONMENT = 'production'.freeze
      MASTER_KEY_VAR = 'RAILS_MASTER_KEY'.freeze
      ENV_SECRETS = [MASTER_KEY_VAR].freeze
      ENV_EXCLUDE = ['RAILS_ENV'].freeze

      attr_reader :definition
      value_field :environment, default: DEFAULT_ENVIRONMENT

      def initialize(definition)
        @definition = definition
      end

      def namespace
        spec = self

        @namespace ||= Namespace.new do
          name "#{spec.selector_app}-#{spec.environment}"
        end
      end

      def service
        spec = self

        @service ||= Service.new do
          name "#{spec.selector_app}-svc"
          namespace spec.namespace.name
          type 'ClusterIP'

          port do
            name 'http'
            port 80
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
      end

      def service_account
        spec = self

        @service_account ||= ServiceAccount.new do
          name "#{spec.selector_app}-sa"
          namespace spec.namespace.name

          labels do
            app spec.selector_app
            role spec.role
          end
        end
      end

      def config_map
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
      end

      def app_secrets
        spec = self

        @secrets ||= Secrets.new do
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
      end

      def registry_secret
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
      end

      def deployment
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
                    path '/health'
                    port 80
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
      end

      def ingress
        spec = self

        @ingress ||= Ingress.new do
          name "#{spec.selector_app}-ingress"
          namespace spec.namespace.name
        end
      end

      def objects
        @objects ||= [
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
