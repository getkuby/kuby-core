# typed: ignore

require 'kuby/railtie'
require 'kubectl-rb/version'
require 'helm-rb/version'
require 'yaml'

begin
  require 'kuby/plugins/rails_app/generators/kuby'
rescue NameError
end

module Kuby
  autoload :BasicLogger,    'kuby/basic_logger'
  autoload :CLIBase,        'kuby/cli_base'
  autoload :Commands,       'kuby/commands'
  autoload :Definition,     'kuby/definition'
  autoload :Dependable,     'kuby/dependable'
  autoload :Dependency,     'kuby/dependency'
  autoload :Docker,         'kuby/docker'
  autoload :Environment,    'kuby/environment'
  autoload :Kubernetes,     'kuby/kubernetes'
  autoload :Middleware,     'kuby/middleware'
  autoload :Plugin,         'kuby/plugin'
  autoload :PluginRegistry, 'kuby/plugin_registry'
  autoload :Plugins,        'kuby/plugins'
  autoload :Tasks,          'kuby/tasks'
  autoload :TrailingHash,   'kuby/trailing_hash'
  autoload :Utils,          'kuby/utils'

  DEFAULT_ENV = 'development'.freeze
  DEFAULT_DB_USER = 'root'.freeze
  DEFAULT_DB_PASSWORD = 'password'.freeze

  class UndefinedEnvironmentError < StandardError; end
  class MissingConfigError < StandardError; end

  class << self
    attr_reader :definition
    attr_writer :logger

    def load!(config_file = nil)
      config_file ||= ENV['KUBY_CONFIG'] || File.join('.', 'kuby.rb')

      unless File.exist?(config_file)
        raise MissingConfigError, "couldn't find Kuby config file at #{config_file}"
      end

      require config_file
    end

    def define(name, &block)
      raise 'Kuby is already configured' if @definition

      @definition = Definition.new(name.to_s)
      @definition.instance_eval(&block)

      @definition.environment.kubernetes.after_configuration
      @definition.environment.configured = true

      @definition
    end

    def environment(name = env)
      definition.environment(name.to_s) || raise(
        UndefinedEnvironmentError, "couldn't find a Kuby environment named "\
        "'#{name}'"
      )
    end

    def register_provider(provider_name, provider_klass)
      providers[provider_name] = provider_klass
    end

    def providers
      @providers ||= {}
    end

    def register_plugin(*args, **kwargs)
      plugins.register(*args, **kwargs)
    end

    def register_distro(distro_name, distro_klass)
      distros[distro_name] = distro_klass
    end

    def distros
      @distros ||= {}
    end

    def plugins
      @plugins ||= PluginRegistry.new
    end

    def logger
      @logger ||= BasicLogger.new(STDERR)
    end

    def register_package(package_name, package_def = nil)
      packages[package_name] = case package_def
        when NilClass
          Kuby::Docker::Packages::SimpleManagedPackage.new(
            package_name
          )
        when String
          Kuby::Docker::Packages::SimpleManagedPackage.new(
            package_def
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

    def register_dependable(name, version_or_callable)
      dependables[name] = Dependable.new(name, version_or_callable)
    end

    def dependables
      @dependables ||= {}
    end

    def env=(env_name)
      @env = env_name.to_s
    end

    def env
      ENV.fetch('KUBY_ENV') do
        (@env || Rails.env rescue nil || DEFAULT_ENV).to_s
      end
    end

    def load_rake_tasks!
      Rake::TaskManager.record_task_metadata = true

      Kuby.plugins.each do |_, plugin_klass|
        plugin_klass.task_dirs.each do |task_dir|
          Dir.glob(File.join(task_dir, '*.rake')).each do |path|
            Rake.load_rakefile(path)
          end
        end
      end
    end
  end
end

# providers
Kuby.register_provider(:docker_desktop, Kuby::Kubernetes::DockerDesktopProvider)
Kuby.register_provider(:bare_metal, Kuby::Kubernetes::BareMetalProvider)

# plugins
Kuby.register_plugin(:system, Kuby::Plugins::System)
Kuby.register_plugin(:rails_app, Kuby::Plugins::RailsApp::Plugin)
Kuby.register_plugin(:nginx_ingress, Kuby::Plugins::NginxIngress)

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

Kuby.register_package(:git, 'git')

# dependables
Kuby.register_dependable(:kubectl, KubectlRb::KUBECTL_VERSION)
Kuby.register_dependable(:helm, HelmRb::HELM_VERSION)
Kuby.register_dependable(:kubernetes, -> {
  version_info = Kuby.environment.kubernetes.provider.kubernetes_cli.version
  version = version_info.dig('serverVersion', 'gitVersion')
  version.sub(/\Av/, '')
})