require 'kuby/railtie'

module Kuby
  autoload :BasicLogger, 'kuby/basic_logger'
  autoload :CLIBase,     'kuby/cli_base'
  autoload :Definition,  'kuby/definition'
  autoload :Docker,      'kuby/docker'
  autoload :Kubernetes,  'kuby/kubernetes'
  autoload :Middleware,  'kuby/middleware'

  class << self
    attr_reader :definition
    attr_accessor :logger

    def define(app = Rails.application, &block)
      @definition = Definition.new(app, &block)
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

    def plugins
      @plugins ||= {}
    end
  end
end

# providers
Kuby.register_provider(:minikube, Kuby::Kubernetes::MinikubeProvider)

# plugins
Kuby.register_plugin(:rails_app, Kuby::Kubernetes::Plugins::RailsApp)
