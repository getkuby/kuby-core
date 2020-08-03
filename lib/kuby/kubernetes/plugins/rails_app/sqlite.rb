module Kuby
  module Kubernetes
    module Plugins
      module RailsApp
        class Sqlite < Kuby::Kubernetes::Plugin
          attr_reader :definition

          def initialize(definition, *)
            @definition = definition
          end

          def after_configuration
            definition.docker.package_phase.add(:sqlite_dev)
            definition.docker.package_phase.add(:sqlite_client)
          end
        end
      end
    end
  end
end

Kuby.register_package(:sqlite_dev,
  debian: 'libsqlite3-dev',
  alpine: 'sqlite-dev'
)

Kuby.register_package(:sqlite_client,
  debian: 'sqlite3',
  alpine: 'sqlite'
)
