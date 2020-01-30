module Kuby
  module Kubernetes
    class ServiceAccount
      extend ValueFields

      value_fields :name, :namespace
      object_field(:labels) { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'ServiceAccount',
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          }
        }
      end

      def kind
        :service_account
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
