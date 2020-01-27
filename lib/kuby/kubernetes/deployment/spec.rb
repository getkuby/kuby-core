module Kuby
  module Kubernetes
    class Deployment
      class Spec
        extend ValueFields

        array_field(:container) { Container.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            containers: containers.map(&:serialize)
          }
        end
      end
    end
  end
end
