require 'kube-dsl'

module Kuby
  module Kubernetes
    module Plugins
      class RailsApp < Plugin
        extend ::KubeDSL::ValueFields

        WEB_ROLE = 'web'.freeze
        MASTER_KEY_VAR = 'RAILS_MASTER_KEY'.freeze
        ENV_SECRETS = [MASTER_KEY_VAR].freeze
        ENV_EXCLUDE = ['RAILS_ENV'].freeze

        value_fields :hostname

        def initialize(definition)
          @definition = definition
        end

        def configure(&block)
          instance_eval(&block) if block
        end

        def service(&block)
          spec = self

          @service ||= KubeDSL.service do
            metadata do
              name "#{spec.selector_app}-svc"
              namespace spec.namespace.metadata.name

              labels do
                app spec.selector_app
                role spec.role
              end
            end

            spec do
              type 'ClusterIP'

              selector do
                app spec.selector_app
                role spec.role
              end

              port do
                name 'http'
                port 8080
                protocol 'TCP'
                target_port 'http'
              end
            end
          end

          @service.instance_eval(&block) if block
          @service
        end

        def service_account(&block)
          spec = self

          @service_account ||= KubeDSL.service_account do
            metadata do
              name "#{spec.selector_app}-sa"
              namespace spec.namespace.metadata.name

              labels do
                app spec.selector_app
                role spec.role
              end
            end
          end

          @service_account.instance_eval(&block) if block
          @service_account
        end

        def config_map(&block)
          spec = self

          @config_map ||= KubeDSL.config_map do
            metadata do
              name "#{spec.selector_app}-config"
              namespace spec.namespace.metadata.name
            end

            data do
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

          @config_map.instance_eval(&block) if block
          @config_map
        end

        def app_secrets(&block)
          spec = self

          @app_secrets ||= KubeDSL.secret do
            metadata do
              name "#{spec.selector_app}-secrets"
              namespace spec.namespace.metadata.name
            end

            type 'Opaque'

            data do
              if master_key = ENV[MASTER_KEY_VAR]
                send(MASTER_KEY_VAR.to_sym, master_key)
              else
                master_key_path = spec.app.root.join('config', 'master.key')

                if master_key_path.exist?
                  send(MASTER_KEY_VAR.to_sym, File.read(master_key_path).strip)
                end
              end
            end
          end

          @app_secrets.instance_eval(&block) if block
          @app_secrets
        end

        def registry_secret(&block)
          spec = self

          @registry_secret ||= RegistrySecret.new do
            metadata do
              name "#{spec.selector_app}-registry-secret"
              namespace spec.namespace.metadata.name
            end

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

          @deployment ||= KubeDSL.deployment do
            metadata do
              name "#{kube_spec.selector_app}-deployment"
              namespace kube_spec.namespace.metadata.name

              labels do
                app kube_spec.selector_app
                role kube_spec.role
              end
            end

            spec do
              selector do
                match_labels do
                  app kube_spec.selector_app
                  role kube_spec.role
                end
              end

              strategy do
                type 'RollingUpdate'

                rolling_update do
                  max_surge '25%'
                  max_unavailable 0
                end
              end

              template do
                metadata do
                  labels do
                    app kube_spec.selector_app
                    role kube_spec.role
                  end
                end

                spec do
                  container(:web) do
                    name "#{kube_spec.selector_app}-#{kube_spec.role}"
                    image_pull_policy 'IfNotPresent'

                    port do
                      container_port kube_spec.docker.webserver_phase.port
                      name 'http'
                      protocol 'TCP'
                    end

                    env_from do
                      config_map_ref do
                        name kube_spec.config_map.metadata.name
                      end
                    end

                    env_from do
                      secret_ref do
                        name kube_spec.app_secrets.metadata.name
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
                    name kube_spec.registry_secret.metadata.name
                  end

                  restart_policy 'Always'
                  service_account_name kube_spec.service_account.metadata.name
                end
              end
            end
          end

          @deployment.instance_eval(&block) if block
          @deployment
        end

        def ingress(&block)
          spec = self

          @ingress ||= KubeDSL.ingress do
            metadata do
              name "#{spec.selector_app}-ingress"
              namespace spec.namespace.metadata.name
            end

            spec do
              rule do
                host spec.hostname

                http do
                  path do
                    backend do
                      service_name spec.service.metadata.name
                      service_port spec.service.spec.ports.first.port
                    end
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
          definition.kubernetes.selector_app
        end

        def role
          WEB_ROLE
        end

        def docker
          definition.docker
        end

        def app
          definition.app
        end

        def namespace
          definition.kubernetes.namespace
        end
      end
    end
  end
end
