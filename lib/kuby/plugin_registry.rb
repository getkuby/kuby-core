module Kuby
  class PluginRegistry
    ANY = 'any'.freeze

    def register(plugin_name, plugin_klass, environment: ANY)
      plugins[plugin_name] ||= {}
      plugins[plugin_name][environment] ||= plugin_klass
    end

    def find(plugin_name, environment: Kuby.env)
      plugins_by_env = plugins[plugin_name]

      unless plugins_by_env
        raise MissingPluginError, "no plugin registered with name #{plugin_name}, "\
          'do you need to add a gem to your Gemfile?'
      end

      plugins_by_env[environment] || plugins_by_env[ANY]
    end

    private

    def plugins
      @plugins ||= {}
    end
  end
end
