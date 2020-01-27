module Kuby
  module Kubernetes
    class Deployment
      class EnvFromEntry
        extend ValueFields

        object_field(:config_map_ref) { ConfigMapRef.new }
        object_field(:secret_ref) { SecretRef.new }

        def initialize(&block)
          instance_eval(&block) if block_given?
        end

        def serialize
          {
            configMapRef: config_map_ref.serialize,
            secretRef: secret_ref.serialize
          }
        end
      end
    end
  end
end
