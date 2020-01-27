module Kuby
  module Kubernetes
    class Deployment
      class SecretRef
        extend ValueFields

        value_fields :name

        def initialize(&block)
          instance_eval(&block) if block_given?
        end

        def serialize
          { name: name }
        end
      end
    end
  end
end
