module Kuby
  class Definition
    attr_reader :app_name

    def initialize(app_name, &block)
      @app_name = app_name
    end

    def environment(name = Kuby.env, &block)
      name = name.to_s

      if name
        environments[name] ||= Environment.new(name, self)
      end

      if block_given?
        environments[name].instance_eval(&block)
      end

      environments[name]
    end

    def docker(&block)
      environment.docker(&block)
    end

    def kubernetes(&block)
      environment.kubernetes(&block)
    end

    def environments
      @environments ||= {}
    end
  end
end
