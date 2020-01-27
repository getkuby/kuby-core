module Kuby
  module Kubernetes
    class Deployment
      class Strategy
        extend ValueFields

        value_fields :type
        object_field(:rolling_update) { RollingUpdate.new }

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            type: type,
            rollingUpdate: rolling_update.serialize
          }
        end
      end
    end
  end
end
