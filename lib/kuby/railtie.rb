# typed: strict

require 'logger'
require 'rails/railtie'
require 'rails/command'
require 'rails/commands/dbconsole/dbconsole_command'

module Kuby
  module CockroachConsoleMonkeypatch
    def start
      config_hash = if respond_to?(:config)
        config_hash = config
      else
        config_hash = db_config.configuration_hash.stringify_keys
      end

      return super unless config_hash['adapter'] == 'cockroachdb'

      ENV['PGUSER']         = config_hash['username'] if config_hash['username']
      ENV['PGHOST']         = config_hash['host'] if config_hash['host']
      ENV['PGPORT']         = config_hash['port'].to_s if config_hash['port']
      ENV['PGPASSWORD']     = config_hash['password'].to_s if config_hash['password'] && @options['include_password']
      ENV['PGSSLMODE']      = config_hash['sslmode'].to_s if config_hash['sslmode']
      ENV['PGSSLCERT']      = config_hash['sslcert'].to_s if config_hash['sslcert']
      ENV['PGSSLKEY']       = config_hash['sslkey'].to_s if config_hash['sslkey']
      ENV['PGSSLROOTCERT']  = config_hash['sslrootcert'].to_s if config_hash['sslrootcert']

      find_cmd_and_exec('psql', config_hash['database'])
    end
  end

  class Railtie < ::Rails::Railtie
    initializer 'kuby.health_check_middleware' do |app|
      app.middleware.use Kuby::Middleware::HealthCheck
    end

    initializer 'kuby.cockroachdb_console_support' do
      Rails::DBConsole.prepend(CockroachConsoleMonkeypatch)
    end
  end
end
