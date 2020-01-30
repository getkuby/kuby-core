module Kuby
  module Kubernetes
    class Deployment
      autoload :ConfigMapRef,    'kuby/kubernetes/deployment/config_map_ref'
      autoload :Container,       'kuby/kubernetes/deployment/container'
      autoload :ContainerPort,   'kuby/kubernetes/deployment/container_port'
      autoload :EnvEntry,        'kuby/kubernetes/deployment/env_entry'
      autoload :EnvFromEntry,    'kuby/kubernetes/deployment/env_from_entry'
      autoload :ImagePullSecret, 'kuby/kubernetes/deployment/image_pull_secret'
      autoload :ReadinessProbe,  'kuby/kubernetes/deployment/readiness_probe'
      autoload :RollingUpdate,   'kuby/kubernetes/deployment/rolling_update'
      autoload :SecretRef,       'kuby/kubernetes/deployment/secret_ref'
      autoload :Spec,            'kuby/kubernetes/deployment/spec'
      autoload :Strategy,        'kuby/kubernetes/deployment/strategy'
      autoload :Template,        'kuby/kubernetes/deployment/template'

      extend ValueFields

      value_fields :name, :namespace
      object_field(:labels)   { Labels.new }
      object_field(:selector) { Selector.new }
      object_field(:strategy) { Strategy.new }
      object_field(:template) { Template.new }

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          apiVersion: 'apps/v1',
          kind: 'Deployment',
          metadata: {
            name: name,
            namespace: namespace,
            labels: labels.serialize
          },
          spec: {
            selector: {
              matchLabels: selector.serialize
            },
            strategy: strategy.serialize,
            template: template.serialize
          }
        }
      end

      def kind
        :deployment
      end

      def to_resource
        Resource.new(serialize)
      end
    end
  end
end
