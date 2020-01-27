module Kuby
  module Kubernetes
    class Deployment
      class Template
        extend ValueFields

        object_field(:spec) { Spec.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            spec: spec.serialize
          }
        end
      end
    end
  end
end
