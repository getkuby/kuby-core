# typed: true

module Kuby
  module Plugins
    module RailsApp
      class Sqlite < ::Kuby::Plugin
        attr_reader :environment

        def initialize(environment, *_)
          @environment = environment
        end

        def after_configuration
          environment.docker.package_phase.add(:sqlite_dev)
          environment.docker.package_phase.add(:sqlite_client)
        end

        def bootstrap
          # no boostrap steps necessary
        end

        def user(_user)
          raise 'SQLite databases do not require a username or password'
        end

        def password(_password)
          raise 'SQLite databases do not require a username or password'
        end

        def name
          :sqlite
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
