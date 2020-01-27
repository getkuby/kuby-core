module Kuby
  module Kubernetes
    class Deployment
      class EnvEntry
        extend ValueFields

        value_fields :name, :value

        def initialize(&block)
          instance_eval(&block) if block_given?
        end

        def serialize
          {
            name: name,
            value: value
          }
        end
      end
    end
  end
end
