module Kuby
  module Kubernetes
    class ConfigMap < KeyValuePairs
      extend ValueFields

      value_fields :name, :namespace
      object_field(:labels) { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'ConfigMap',
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          },
          data: super
        }
      end

      def kind
        :config_map
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
