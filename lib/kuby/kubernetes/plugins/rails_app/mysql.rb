require 'kube-dsl'

module Kuby
  module Kubernetes
    module Plugins
      class RailsApp < Plugin
        class MySQL < Plugin
          attr_reader :definition, :environment, :configs

          def initialize(definition, environment, configs)
            @definition = definition
            @environment = environment
            @configs = configs

            user(config['username'])
            password(config['password'])
          end

          def resources
            @resources ||= [secret, database]
          end

          def after_configuration
            definition.docker.package_phase.add(:mysql_dev)
            definition.docker.package_phase.add(:mysql_client)
          end

          def host
            # host is the same as the name thanks to k8s DNS
            @host ||= database.metadata.name
          end

          def rewritten_configs
            # deep dup
            @rewritten_configs ||= Marshal.load(Marshal.dump(configs)).tap do |new_configs|
              new_configs[environment]['host'] = host
            end
          end

          def user(user)
            secret do
              data do
                set :user, user
              end
            end
          end

          def password(password)
            secret do
              data do
                set :password, password
              end
            end
          end

          def secret(&block)
            context = self

            @secret ||= KubeDSL.secret do
              metadata do
                name "#{context.base_name}-mysql-secret"
                namespace context.kubernetes.namespace.metadata.name
              end

              type 'Opaque'
            end

            @secret.instance_eval(&block) if block
            @secret
          end

          def database(&block)
            context = self

            @database ||= Kuby::KubeDB.my_sql do
              api_version 'kubedb.com/v1alpha1'

              metadata do
                name "#{context.base_name}-mysql"
                namespace context.kubernetes.namespace.metadata.name
              end

              spec do
                database_secret do
                  secret_name context.secret.metadata.name
                end

                version '5.7-v2'
                storage_type 'Durable'

                storage do
                  storage_class_name context.kubernetes.provider.storage_class_name
                  access_modes ['ReadWriteOnce']

                  resources do
                    requests do
                      add :storage, '10Gi'
                    end
                  end
                end

                termination_policy 'DoNotTerminate'
              end
            end

            @database.instance_eval(&block) if block
            @database
          end

          def base_name
            @base_name ||= "#{kubernetes.selector_app}-#{environment}"
          end

          def kubernetes
            definition.kubernetes
          end

          def app
            definition.app
          end

          private

          def config
            configs[environment]
          end
        end
      end
    end
  end
end

Kuby.register_package(:mysql_client,
  debian: 'default-mysql-client',
  alpine: 'mariadb-client'
)

Kuby.register_package(:mysql_dev,
  debian: 'default-libmysqlclient-dev',
  alpine: 'mariadb-dev'
)
