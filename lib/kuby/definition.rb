module Kuby
  class Definition
    attr_reader :app_name

    def initialize(app_name, &block)
      @app_name = app_name
    end

    def environment(name = Kuby.env, &block)
      name = name.to_s

      environments[name] ||= Environment.new(name, self)
      # if name == 'development'
      #   environments[name] ||= make_default_dev_env
      # else
      #   environments[name] ||= Environment.new(name, self)
      # end

      if block_given?
        environments[name].instance_eval(&block)
      end

      environments[name]
    end

    def environments
      @environments ||= {}
    end

    private

    # def make_default_dev_env
    #   Environment.new('development', self).tap do |env|
    #     env.instance_eval do
    #       kubernetes do
    #         add_plugin(:rails_app) do
    #           tls_enabled false
    #         end

    #         provider :docker_desktop
    #       end
    #     end
    #   end
    # end
  end
end
