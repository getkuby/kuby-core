module Kuby
  module Kubernetes
    class Spec
      WEB_ROLE = 'web'.freeze

      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end

      def service
        spec = self

        @service ||= Service.new do
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
          name "#{spec.selector_app}-#{spec.role}"

          labels do
            app spec.selector_app
            role spec.role
          end
        end
      end

      def config_map
        spec = self

        @config_map ||= ConfigMap.new do
          name spec.selector_app
        end
      end

      def app_secrets
        spec = self

        @secrets ||= Secrets.new do
          type 'Opaque'
          name spec.selector_app
        end
      end

      def image_pull_secrets
        @image_pull_secrets ||= Secrets.new do
          # type 'docker-registry'
        end
      end

      def deployment
        kube_spec = self

        @deployment ||= Deployment.new do
          name kube_spec.selector_app

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
                image kube_spec.image_url
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
              end
            end
          end
        end
      end

      def ingress
        @ingress ||= Ingress.new
      end

      def resources
        @resources ||= [
          service,
          service_account,
          config_map,
          app_secrets,
          image_pull_secrets,
          deployment,
          ingress
        ]
      end

      def namespace
        @namespace ||= "#{selector_app}-production"
      end

      def selector_app
        @selector_app ||= definition.app_name.downcase
      end

      def role
        WEB_ROLE
      end

      def image_url
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
    end
  end
end
