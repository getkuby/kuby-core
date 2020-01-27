module Kuby
  module Kubernetes
    class Service
      extend ValueFields

      value_fields :name, :type
      array_field(:port)      { ServicePort.new }
      object_field(:selector) { Selector.new }
      object_field(:labels)   { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'Service',
          metadata: {
            name: name,
            labels: labels.serialize
          },
          spec: {
            type: type,
            ports: ports.map(&:serialize),
            selector: selector.serialize
          }
        }
      end
    end
  end
end
