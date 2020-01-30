require 'base64'

module Kuby
  module Kubernetes
    class Secrets < KeyValuePairs
      extend ValueFields

      attr_reader :labels

      value_fields :name, :namespace, :type
      object_field(:labels) { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'Secret',
          type: type,
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          },
          data: super.each_with_object({}) do |(k, v), ret|
            ret[k] = Base64.strict_encode64(v)
          end
        }
      end

      def kind
        :secret
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
