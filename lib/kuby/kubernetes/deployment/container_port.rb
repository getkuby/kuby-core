module Kuby
  module Kubernetes
    class Deployment
      class ContainerPort
        extend ValueFields

        value_fields :name, :container_port, :protocol

        def initialize(&block)
          instance_eval(&block) if block
        end

        def serialize
          {
            name: name,
            containerPort: container_port,
            protocol: protocol
          }
        end
      end
    end
  end
end
