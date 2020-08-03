require 'erb'
require 'yaml'

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

          def self.get(rails_app)
            new(rails_app).database
          end

          def self.get_adapter(adapter)
            ADAPTER_MAP.fetch(adapter) do
              raise UnsupportedDatabaseError, "Kuby does not support the '#{adapter}' "\
                'database adapter'
            end
          end

          attr_reader :rails_app

          def initialize(rails_app)
            @rails_app = rails_app
          end

          def database
            @database ||= self.class
              .get_adapter(adapter)
              .new(rails_app, environment, db_configs)
          end

          private

          def adapter
            db_config['adapter']
          end

          def db_config
            @db_config ||= db_configs[environment]
          end

          def environment
            @environment ||= rails_app.definition.environment
          end

          def db_configs
            @db_configs ||= YAML.load(ERB.new(File.read(db_config_path)).result)
          end

          def db_config_path
            @db_config_path ||= begin
              db_config_paths.first or
                raise "Couldn't find database config at #{rails_app.root}"
            end
          end

          def db_config_paths
            @db_config_paths ||=
              Dir.glob(
                File.join(
                  rails_app.root, 'config', 'database.{yml,erb,yml.erb,yaml,yaml.erb}'
                )
              )
          end
        end
      end
    end
  end
end
