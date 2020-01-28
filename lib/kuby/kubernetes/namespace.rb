module Kuby
  module Kubernetes
    class Namespace
      extend ValueFields

      value_fields :name

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'Namespace',
          metadata: {
            name: name
          }
        }
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
