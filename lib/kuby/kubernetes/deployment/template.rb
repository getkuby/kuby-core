module Kuby
  module Kubernetes
    class Deployment
      class Template
        extend ValueFields

        object_field(:spec) { Spec.new }
        object_field(:labels) { Labels.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            metadata: {
              labels: labels.serialize
            },
            spec: spec.serialize
          }
        end
      end
    end
  end
end
