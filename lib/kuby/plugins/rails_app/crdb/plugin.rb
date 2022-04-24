# typed: ignore

require 'fileutils'
require 'kuby/crdb'
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

          attr_reader :environment, :configs

          def initialize(environment, configs)
            @environment = environment
            @configs = configs

            add_client_user('root')
            add_client_user(client_username)
          end

          def add_client_user(username, &block)
            crdb = self
            safe_username = slugify(username)

            client_certs[username] ||= Kuby::CertManager.certificate do
              api_version 'cert-manager.io/v1'

              metadata do
                name "#{crdb.base_name}-crdb-#{safe_username}-cert"
                namespace crdb.kubernetes.namespace.metadata.name
              end

              spec do
                common_name username
                secret_name "#{crdb.base_name}-crdb-client-#{safe_username}-cert"

                subject do
                  organizations ['Kuby']
                end

                usages ['client auth']
                duration "#{5 * 365 * 24}h"  # 5 years validity (in hours)

                private_key do
                  algorithm 'RSA'
                  size 2048
                end

                issuer_ref do
                  name crdb.issuer.metadata.name
                  kind 'Issuer'
                  group 'cert-manager.io'
                end
              end
            end

            client_certs[username].instance_eval(&block) if block
            client_certs[username]
          end

          alias_method :configure_client_user, :add_client_user

          def client_certs
            @client_certs ||= {}
          end

          def name
            :cockroachdb
          end

          def resources
            @resources ||= [
              database,
              cluster_issuer, issuer,
              ca_cert, node_cert, *client_certs.values
            ]
          end

          def after_configuration
            environment.docker.package_phase.add(:postgres_dev)
            environment.docker.package_phase.add(:postgres_client)

            environment.kubernetes.add_plugin(:crdb)
            environment.kubernetes.add_plugin(:cert_manager)
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

            client_certs.each do |username, _cert|
              unless existing_users.include?(username)
                conn.exec("create user #{username}")
              end

              conn.exec(
                "grant #{CLIENT_PERMISSIONS.join(',')} "\
                  "on database #{database_name} "\
                  "to #{username}"
              )
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
                    name crdb.node_cert.spec.secret_name

                    item do
                      key 'ca.crt'
                      path 'ca.crt'
                    end
                  end
                end

                crdb.client_certs.each do |username, cert|
                  source do
                    secret do
                      name cert.spec.secret_name

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
            crdb = self

            @database ||= Kuby::CRDB.crdb_cluster do
              metadata do
                # this translates to the name of the statefulset that is created
                name "#{crdb.base_name}-crdb"
                namespace crdb.kubernetes.namespace.metadata.name
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
                    add :cpu, '200m'
                    add :memory, '1Gi'
                  end

                  limits do
                    add :cpu, '200m'
                    add :memory, '1Gi'
                  end
                end

                tls_enabled true
                client_tls_secret crdb.client_certs['root'].spec.secret_name
                node_tls_secret crdb.node_cert.spec.secret_name

                image do
                  name "cockroachdb/cockroach:v#{VERSION}"
                end

                # this is unfortunately the minimum
                nodes 3
              end
            end
          end

          def cluster_issuer
            crdb = self

            @cluster_issuer ||= Kuby::CertManager.cluster_issuer do
              api_version 'cert-manager.io/v1'

              metadata do
                name "#{crdb.base_name}-crdb-ca-issuer"
              end

              spec do
                self_signed
              end
            end
          end

          def issuer
            crdb = self

            @issuer ||= Kuby::CertManager.issuer do
              api_version 'cert-manager.io/v1'

              metadata do
                name "#{crdb.base_name}-crdb-issuer"
                namespace crdb.kubernetes.namespace.metadata.name
              end

              spec do
                ca do
                  secret_name crdb.ca_cert.spec.secret_name
                end
              end
            end
          end

          def ca_cert
            crdb = self

            @ca_cert ||= Kuby::CertManager.certificate do
              api_version 'cert-manager.io/v1'

              metadata do
                name "#{crdb.base_name}-crdb-ca-cert"
                namespace crdb.kubernetes.namespace.metadata.name
              end

              spec do
                is_ca true
                common_name 'ca'
                secret_name "#{crdb.base_name}-crdb-ca-cert"

                subject do
                  organizations ['Kuby']
                end

                usages ['digital signature', 'key encipherment', 'cert sign', 'crl sign']
                duration "#{5 * 365 * 24}h"  # 5 years validity (in hours)

                private_key do
                  algorithm 'RSA'
                  size 2048
                end

                issuer_ref do
                  name crdb.cluster_issuer.metadata.name
                  kind 'ClusterIssuer'
                  group 'cert-manager.io'
                end
              end
            end
          end

          def node_cert
            crdb = self
            ns = kubernetes.namespace.metadata.name

            @node_cert ||= Kuby::CertManager.certificate do
              api_version 'cert-manager.io/v1'

              metadata do
                name "#{crdb.base_name}-crdb-node-cert"
                namespace ns
              end

              spec do
                common_name 'node'
                secret_name "#{crdb.base_name}-crdb-node-cert"

                subject do
                  organizations ['Kuby']
                end

                usages ['client auth', 'server auth']
                duration "#{5 * 365 * 24}h"  # 5 years validity (in hours)

                svc_name = "#{crdb.base_name}-crdb"

                dns_names [
                  'localhost',
                  "#{svc_name}-public",
                  "#{svc_name}-public.#{ns}",
                  "#{svc_name}-public.#{ns}.svc.cluster.local",
                  "*.#{svc_name}",
                  "*.#{svc_name}.#{ns}",
                  "*.#{svc_name}.#{ns}.svc.cluster.local",
                ]

                ip_addresses ['127.0.0.1']

                private_key do
                  algorithm 'RSA'
                  size 2048
                end

                issuer_ref do
                  name crdb.issuer.metadata.name
                  kind 'Issuer'
                  group 'cert-manager.io'
                end
              end
            end
          end

          def client_username
            @client_username ||= slugify(kubernetes.selector_app)
          end

          # replaces all non-ascii characters with an underscore
          def slugify(str)
            str.gsub(/\W/, '_')
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
