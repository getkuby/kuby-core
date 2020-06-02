module Kuby
  class Definition
    attr_reader :environment, :app

    def initialize(environment, app, &block)
      @environment = environment
      @app = app

      instance_eval(&block) if block
      kubernetes.after_configuration
    end

    def docker(&block)
      @docker ||= Docker::Spec.new(self)
      @docker.instance_eval(&block) if block
      @docker
    end

    def kubernetes(&block)
      @kubernetes ||= Kubernetes::Spec.new(self)
      @kubernetes.instance_eval(&block) if block
      @kubernetes
    end

    def app_name
      @app_name ||= app.class.module_parent.name
    end
  end
end
