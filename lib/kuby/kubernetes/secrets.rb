module Kuby
  module Kubernetes
    class Secrets < KeyValuePairs
      extend ValueFields

      attr_reader :labels

      value_fields :name
      object_field(:labels) { Labels.new }

      def initialize(&block)
        super
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'Secret',
          metadata: {
            labels: labels.serialize
          },
          data: super
        }
      end
    end
  end
end
