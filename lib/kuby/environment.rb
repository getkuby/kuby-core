module Kuby
  class Environment
    attr_reader :name, :definition

    def initialize(name, definition, &block)
      @name = name
      @definition = definition
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
      definition.app_name
    end
  end
end
