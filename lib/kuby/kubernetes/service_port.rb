module Kuby
  module Kubernetes
    class ServicePort
      extend ValueFields

      value_fields :name, :port, :target_port, :protocol

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          name: name,
          port: port,
          target_port: target_port,
          protocol: protocol
        }
      end
    end
  end
end
