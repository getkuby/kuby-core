module Kuby
  module Kubernetes
    class ServiceAccount
      extend ValueFields

      value_fields :name
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
            labels: labels.serialize
          }
        }
      end
    end
  end
end
