module Kuby
  module Kubernetes
    class Ingress
      autoload :Backend, 'kuby/kubernetes/ingress/backend'
      autoload :Http,    'kuby/kubernetes/ingress/http'
      autoload :Path,    'kuby/kubernetes/ingress/path'
      autoload :Rule,    'kuby/kubernetes/ingress/rule'

      extend ValueFields

      value_fields :name, :namespace
      object_field(:labels) { Labels.new }
      array_field(:rule) { Rule.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'networking.k8s.io/v1beta1',
          kind: 'Ingress',
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          },
          spec: {
            rules: rules.map(&:serialize)
          }
        }
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
