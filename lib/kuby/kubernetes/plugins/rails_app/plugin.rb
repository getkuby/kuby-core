require 'kube-dsl'
require 'kuby/cert-manager'

module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        class Plugin < Kuby::Kubernetes::Plugin
          extend ::KubeDSL::ValueFields

          WEB_ROLE = 'web'.freeze
          MASTER_KEY_VAR = 'RAILS_MASTER_KEY'.freeze
          ENV_SECRETS = [MASTER_KEY_VAR].freeze
          ENV_EXCLUDE = ['RAILS_ENV'].freeze

          value_fields :hostname, :tls_enabled, :database, :replicas

          def initialize(definition)
            @definition = definition
            @tls_enabled = true
            @replicas = 1
          end

          def configure(&block)
            instance_eval(&block) if block
          end

          def after_configuration
            # currently Database.get doesn't return nil, but this if statement
            # is here as a placeholder to indicate we'd like to be able to
            # handle Rails apps that don't use a database, i.e. don't have
            # activerecord configured
            if @database = Database.get(definition)
              definition.kubernetes.plugins[database] = @database
              definition.kubernetes.add_plugin(:kube_db)

              definition.docker do
                insert :rewrite_db_config, RewriteDbConfig.new, after: :copy_phase
              end
            end

            # do we always want this?
            definition.kubernetes.add_plugin(:nginx_ingress)

            if @tls_enabled
              definition.kubernetes.add_plugin(:cert_manager)
            end
          end

          def before_deploy(manifest)
            # Make sure plugin has been configured. If not, do nothing.
            if cert_manager = definition.kubernetes.plugin(:cert_manager)
              if ing = manifest.find(:ingress, ingress.metadata.name)
                cert_manager.annotate_ingress(ing)
              end
            end

            image_with_tag = "#{docker.metadata.image_url}:#{kubernetes.tag}"

            deployment do
              spec do
                template do
                  spec do
                    container(:web) do
                      image image_with_tag
                    end

                    init_container(:create_db) do
                      image image_with_tag
                    end

                    init_container(:migrate_db) do
                      image image_with_tag
                    end
                  end
                end
              end
            end
          end

          def database(&block)
            @database.instance_eval(&block) if block
            @database
          end

          def service(&block)
            spec = self

            @service ||= KubeDSL.service do
              metadata do
                name "#{spec.selector_app}-svc"
                namespace spec.namespace.metadata.name

                labels do
                  add :app, spec.selector_app
                  add :role, spec.role
                end
              end

              spec do
                type 'NodePort'

                selector do
                  add :app, spec.selector_app
                  add :role, spec.role
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
                  add :app, spec.selector_app
                  add :role, spec.role
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
                    add key.to_sym, val
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
                  add MASTER_KEY_VAR.to_sym, master_key
                else
                  master_key_path = spec.app.root.join('config', 'master.key')

                  if master_key_path.exist?
                    add MASTER_KEY_VAR.to_sym, File.read(master_key_path).strip
                  end
                end
              end
            end

            @app_secrets.instance_eval(&block) if block
            @app_secrets
          end

          def deployment(&block)
            kube_spec = self

            @deployment ||= KubeDSL.deployment do
              metadata do
                name "#{kube_spec.selector_app}-#{kube_spec.role}"
                namespace kube_spec.namespace.metadata.name

                labels do
                  add :app, kube_spec.selector_app
                  add :role, kube_spec.role
                end
              end

              spec do
                replicas kube_spec.replicas

                selector do
                  match_labels do
                    add :app, kube_spec.selector_app
                    add :role, kube_spec.role
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
                      add :app, kube_spec.selector_app
                      add :role, kube_spec.role
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

                    init_container(:create_db) do
                      name "#{kube_spec.selector_app}-create-db"
                      command %w(bundle exec rake kuby:rails_app:db:create_unless_exists)
                    end

                    init_container(:migrate_db) do
                      name "#{kube_spec.selector_app}-migrate-db"
                      command %w(bundle exec rake db:migrate)
                    end

                    image_pull_secret do
                      name kube_spec.definition.kubernetes.registry_secret.metadata.name
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
            tls_enabled = @tls_enabled

            @ingress ||= KubeDSL::DSL::Extensions::V1beta1::Ingress.new do
              metadata do
                name "#{spec.selector_app}-ingress"
                namespace spec.namespace.metadata.name

                annotations do
                  add :'kubernetes.io/ingress.class', 'nginx'
                end
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

                if tls_enabled
                  tls do
                    secret_name "#{spec.selector_app}-tls"
                    hosts [spec.hostname]
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
              deployment,
              ingress,
              *database.resources
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

          def kubernetes
            definition.kubernetes
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
end
