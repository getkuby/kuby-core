require 'kuby/railtie'

module Kuby
  autoload :BasicLogger,  'kuby/basic_logger'
  autoload :CLIBase,      'kuby/cli_base'
  autoload :Definition,   'kuby/definition'
  autoload :Docker,       'kuby/docker'
  autoload :Kubernetes,   'kuby/kubernetes'
  autoload :Middleware,   'kuby/middleware'
  autoload :Tasks,        'kuby/tasks'
  autoload :TrailingHash, 'kuby/trailing_hash'

  class UndefinedEnvironmentError < StandardError; end

  class << self
    attr_reader :definition
    attr_accessor :logger

    def define(environment, app = Rails.application, &block)
      environment = environment.to_s
      definitions[environment] ||= Definition.new(environment, app, &block)
    end

    def definitions
      @definitions ||= {}
    end

    def definition(environment = env)
      definitions.fetch(environment.to_s) do
        raise UndefinedEnvironmentError, "couldn't find a Kuby environment named "\
          "'#{environment}'"
      end
    end

    def register_provider(provider_name, provider_klass)
      providers[provider_name] = provider_klass
    end

    def providers
      @providers ||= {}
    end

    def register_plugin(plugin_name, plugin_klass)
      plugins[plugin_name] = plugin_klass
    end

    def register_distro(distro_name, distro_klass)
      distros[distro_name] = distro_klass
    end

    def distros
      @distros ||= {}
    end

    def plugins
      @plugins ||= {}
    end

    def register_package(package_name, package_def)
      packages[package_name] = case package_def
        when String
          Kuby::Docker::Packages::ManagedPackage.new(
            package_name, debian: package_def, alpine: package_def
          )
        when Hash
          Kuby::Docker::Packages::ManagedPackage.new(
            package_name, package_def
          )
        else
          package_def.new(package_name)
      end
    end

    def packages
      @packages ||= {}
    end

    def env
      ENV.fetch('KUBY_ENV') do
        (definitions.keys.first || Rails.env).to_s
      end
    end
  end
end

# providers
Kuby.register_provider(:minikube, Kuby::Kubernetes::MinikubeProvider)

# plugins
Kuby.register_plugin(:rails_app, Kuby::Kubernetes::Plugins::RailsApp)
Kuby.register_plugin(:nginx_ingress, Kuby::Kubernetes::Plugins::NginxIngress)

# distros
Kuby.register_distro(:debian, Kuby::Docker::Debian)
Kuby.register_distro(:alpine, Kuby::Docker::Alpine)

# packages
Kuby.register_package(:nodejs, Kuby::Docker::Packages::Nodejs)
Kuby.register_package(:yarn, Kuby::Docker::Packages::Yarn)

Kuby.register_package(:ca_certificates, 'ca-certificates')
Kuby.register_package(:tzdata, 'tzdata')

Kuby.register_package(:c_toolchain,
  debian: 'build-essential',
  alpine: 'build-base'
)

Kuby.register_package(:sqlite_dev,
  debian: 'libsqlite3-dev',
  alpine: 'sqlite-dev'
)
