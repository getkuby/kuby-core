# typed: false

require 'fileutils'
require 'kube-dsl'

module Kuby
  module Plugins
    module RailsApp
      module CRDB
        class Plugin < ::Kuby::Plugin
          ROLE = 'web'.freeze
          VERSION = '21.1.11'.freeze
          BOOTSTRAP_TIMEOUT_INTERVAL = 2
          BOOTSTRAP_TIMEOUT_TOTAL = 60
          CLIENT_PERMISSIONS = %w(create drop select insert delete update).freeze

          attr_reader :environment, :configs, :client_set

          def initialize(environment, configs)
            @environment = environment
            @configs = configs

            base_path = File.join(rails_app.root, 'config', 'certs', environment.name)
            FileUtils.mkdir_p(base_path)

            @client_set = ClientSet.new(
              base_path: base_path,
              base_name: base_name,
              namespace: kubernetes.namespace.metadata.name,
              master_key: rails_app.master_key
            )

            add_client_user('root')
            add_client_user(client_username, CLIENT_PERMISSIONS)
          end

          def add_client_user(username, permissions = CLIENT_PERMISSIONS)
            client_set.add(username, permissions)
          end

          def name
            :cockroachdb
          end

          def resources
            @resources ||= [database, node_secret, *client_secrets.values]
          end

          def after_configuration
            environment.docker.package_phase.add(:postgres_dev)
            environment.docker.package_phase.add(:postgres_client)

            configure_pod_spec(rails_app.deployment.spec.template.spec)
          end

          def node_secret
            @node_secret ||= client_set.make_node_secret
          end

          def client_secrets
            @client_secrets ||= client_set.each_with_object({}) do |(username, _), memo|
              memo[username] = client_set.make_client_secret(username)
            end
          end

          def bootstrap
            require 'pg'

            config = configs[environment.name]
            database_name = config['database']
            start_time = Time.now

            conn = loop do
              Kuby.logger.info('Waiting for successful database connection...')

              begin
                conn = PG.connect(
                  dbname: database_name,
                  user: 'root',
                  host: host,
                  port: 26257,
                  sslmode: 'require',
                  sslrootcert: '/cockroach/cockroach-certs/ca.crt',
                  sslcert: '/cockroach/cockroach-certs/client.root.crt',
                  sslkey: '/cockroach/cockroach-certs/client.root.key',
                  connect_timeout: BOOTSTRAP_TIMEOUT_INTERVAL
                )
              rescue PG::ConnectionBad => e
                if (Time.now - start_time) > BOOTSTRAP_TIMEOUT_TOTAL
                  Kuby.logger.fatal("Database connection failed, waited #{BOOTSTRAP_TIMEOUT_TOTAL}")
                  raise e
                end

                sleep 1  # breathe!
              else
                Kuby.logger.info('Database connection succeeded')
                break conn
              end
            end

            existing_databases = conn.exec('show databases').to_a

            if existing_databases.none? { |db| db['database_name'] == database_name }
              conn.exec("create database #{database_name}")
            end

            existing_users = conn.exec('show users').to_a.map { |u| u['username'] }

            client_set.each do |username, client|
              unless existing_users.include?(username)
                conn.exec("create user #{username}")
              end

              unless client.permissions.empty?
                conn.exec(
                  "grant #{client.permissions.join(',')} "\
                    "on database #{database_name} "\
                    "to #{username}"
                )
              end
            end
          end

          def kubernetes_cli
            provider.kubernetes_cli
          end

          def provider
            environment.kubernetes.provider
          end

          def configure_pod_spec(pod_spec)
            crdb = self

            pod_spec.containers.each do |container|
              configure_container(container)
            end

            pod_spec.init_containers.each do |init_container|
              configure_container(init_container)
            end

            pod_spec.volume do
              name "#{crdb.base_name}-crdb-certs"

              projected do
                source do
                  secret do
                    name crdb.node_secret.metadata.name

                    item do
                      key 'ca.crt'
                      path 'ca.crt'
                    end
                  end
                end

                crdb.client_set.each do |username, client|
                  source do
                    secret do
                      name crdb.client_secrets[username].metadata.name

                      item do
                        key 'tls.crt'
                        path "client.#{username}.crt"
                      end

                      item do
                        key 'tls.key'
                        path "client.#{username}.key"
                      end
                    end
                  end
                end

                # read-only for user
                # http://permissions-calculator.org/decode/0400/
                default_mode 0400
              end
            end
          end

          def configure_container(container)
            crdb = self

            container.volume_mount do
              name "#{crdb.base_name}-crdb-certs"
              mount_path '/cockroach/cockroach-certs/'
            end
          end

          def host
            # host is the same as the name thanks to k8s DNS
            @host ||= "#{database.metadata.name}-public"
          end

          def rewritten_configs
            # deep dup
            @rewritten_configs ||= Marshal.load(Marshal.dump(configs)).tap do |new_configs|
              new_config = new_configs[environment.name]
              new_config.delete('password')
              new_config.merge!(
                'username' => client_username,
                'host' => host,
                'port' => 26257,
                'sslmode' => 'require',
                'sslrootcert' => '/cockroach/cockroach-certs/ca.crt',
                'sslcert' => "/cockroach/cockroach-certs/client.#{client_username}.crt",
                'sslkey' => "/cockroach/cockroach-certs/client.#{client_username}.key"
              )
            end
          end

          def storage(amount)
            database do
              spec do
                data_store do
                  pvc do
                    spec do
                      resources do
                        requests do
                          set :storage, amount
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          def database(&block)
            context = self

            @database ||= Kuby::CRDB.crdb_cluster do
              metadata do
                # this translates to the name of the statefulset that is created
                name "#{context.base_name}-crdb"
                namespace context.kubernetes.namespace.metadata.name
              end

              spec do
                data_store do
                  pvc do
                    spec do
                      access_modes ['ReadWriteOnce']
                      resources do
                        requests do
                          add :storage, '10Gi'
                        end
                      end

                      volume_mode 'Filesystem'
                    end
                  end
                end

                resources do
                  requests do
                    add :cpu, '500m'
                    add :memory, '1Gi'
                  end

                  limits do
                    add :cpu, 2
                    add :memory, '2Gi'
                  end
                end

                tls_enabled true
                client_tls_secret context.client_secrets['root'].metadata.name
                node_tls_secret context.node_secret.metadata.name

                image do
                  name "cockroachdb/cockroach:v#{VERSION}"
                end

                nodes 3
              end
            end
          end

          def client_username
            # replace illegal characters
            @client_username ||= kubernetes.selector_app.gsub(/\W/, '_')
          end

          def base_name
            @base_name ||= "#{kubernetes.selector_app}-#{ROLE}"
          end

          def kubernetes
            environment.kubernetes
          end

          def rails_app
            kubernetes.plugin(:rails_app)
          end

          private

          def config
            configs[environment.name]
          end
        end
      end
    end
  end
end

Kuby.register_package(:postgres_dev,
  debian: 'postgresql-client',
  alpine: 'postgresql-dev'
)

Kuby.register_package(:postgres_client,
  debian: 'postgresql-client',
  alpine: 'postgresql-client'
)
