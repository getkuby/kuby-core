# typed: false
module Kuby
  class PluginRegistry
    include Enumerable

    ANY = 'any'.freeze

    def register(plugin_name, plugin_klass, environment: ANY)
      plugins[plugin_name] ||= {}
      plugins[plugin_name][environment] ||= plugin_klass
    end

    def find(plugin_name, environment: Kuby.env)
      plugins_by_env = plugins[plugin_name]

      unless plugins_by_env
        raise Kubernetes::MissingPluginError, "no plugin registered with name #{plugin_name}, "\
          'do you need to add a gem to your Gemfile?'
      end

      plugins_by_env[environment] || plugins_by_env[ANY]
    end

    def each(&block)
      return to_enum(__method__) unless block

      @plugins.each_pair do |plugin_name, plugins_by_env|
        plugins_by_env.each_pair do |env, plugin_klass|
          case env
            when ANY, Kuby.env
              yield plugin_name, plugin_klass
          end
        end
      end
    end

    private

    def plugins
      @plugins ||= {}
    end
  end
end
