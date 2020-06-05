module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        class UnsupportedDatabaseError < StandardError; end

        class Database
          ADAPTER_MAP = {
            'sqlite3' => Sqlite,
            'mysql2' => MySQL,
            'postgresql' => Postgres
          }.freeze

          def self.get(definition)
            new(definition).database
          end

          def self.get_adapter(adapter)
            ADAPTER_MAP.fetch(adapter) do
              raise UnsupportedDatabaseError, "Kuby does not support the '#{adapter}'"\
                'database adapter'
            end
          end

          attr_reader :definition

          def initialize(definition)
            @definition = definition
          end

          def database
            @database ||= self.class
              .get_adapter(adapter)
              .new(definition, environment, db_configs)
          end

          private

          def adapter
            db_config['adapter']
          end

          def db_config
            @db_config ||= db_configs[environment]
          end

          def environment
            @environment ||= definition.environment
          end

          def db_configs
            @db_configs ||= definition.app.config.database_configuration
          end
        end
      end
    end
  end
end
