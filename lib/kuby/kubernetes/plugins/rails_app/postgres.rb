require 'kube-dsl'
require 'kuby/kube-db'

module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        class Postgres < Kuby::Kubernetes::Plugin
          def initialize(definition, environment, configs)
            @definition = definition
            @environment = environment
            @configs = configs

            user(config['username'])
            password(config['password'])
          end

          def database(&block)
            context = self

            @database ||= Kuby::KubeDB.my_sql do
              api_version 'kubedb.com/v1alpha1'

              metadata do
                name "#{context.base_name}-postgres"
                namespace context.kubernetes.namespace.metadata.name
              end

              spec do
                database_secret do
                  secret_name context.secret.metadata.name
                end

                version '9.6-v1'
                standby_mode 'Hot'
                streaming_mode 'asynchronous'
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

                init do
                  script_source do
                    config_map do
                      name 'pg-init-script'
                    end
                  end
                end

                termination_policy 'DoNotTerminate'
              end
            end

            @database.instance_eval(&block) if block
            @database
          end
        end
      end
    end
  end
end
