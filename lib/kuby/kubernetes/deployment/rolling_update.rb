module Kuby
  module Kubernetes
    class Deployment
      class RollingUpdate
        extend ValueFields

        value_fields :max_surge, :max_unavailable

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            maxSurge: max_surge,
            maxUnavailable: max_unavailable
          }
        end
      end
    end
  end
end
