module Kuby
  class Definition
    extend KubeDSL::ValueFields

    value_field :app_name, default: -> { raise 'Please set app_name in your Kuby config' }

    attr_reader :environment

    def initialize(environment, &block)
      @environment = environment

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
  end
end
