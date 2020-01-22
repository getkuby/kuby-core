module Kuby
  class Definition
    attr_reader :app

    def initialize(app, &block)
      @app = app
      instance_eval(&block) if block
    end

    def docker(&block)
      @docker ||= Docker::Builder.new(app, &block)
    end

    def app_name
      @app_name ||= app.class.module_parent.name
    end

    def docker_image_name
      @docker_image_name ||= app_name.downcase
    end
  end
end
