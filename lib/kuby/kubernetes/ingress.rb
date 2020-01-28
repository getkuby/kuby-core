module Kuby
  module Kubernetes
    class Ingress
      extend ValueFields

      value_fields :name, :namespace
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
            namespace: namespace,
            labels: labels.serialize
          },
          spec: {
          }
        }
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
