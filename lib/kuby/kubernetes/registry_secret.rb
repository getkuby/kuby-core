require 'base64'

module Kuby
  module Kubernetes
    class RegistrySecret
      extend ValueFields

      attr_reader :labels

      value_fields :name, :namespace
      array_field(:docker_config) { DockerConfig.new }
      object_field(:labels) { Labels.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'v1',
          kind: 'Secret',
          type: 'kubernetes.io/dockerconfigjson',
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          },
          data: {
            :".dockerconfigjson" => Base64.strict_encode64({
              auths: docker_configs.each_with_object({}) do |dc, ret|
                ret.merge!(dc.serialize)
              end
            }.to_json)
          }
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
