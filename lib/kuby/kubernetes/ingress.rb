module Kuby
  module Kubernetes
    class Ingress
      extend ValueFields

      value_fields :name
      object_field(:labels) { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'extensions/v1beta1',
          kind: 'Ingress',
          metadata: {
            name: name,
            labels: labels.serialize
          },
          spec: {
          }
        }
      end
    end
  end
end
