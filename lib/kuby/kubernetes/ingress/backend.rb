module Kuby
  module Kubernetes
    class Ingress
      class Backend
        extend ValueFields

        value_fields :service_name, :service_port

        def serialize
          {
            serviceName: service_name,
            servicePort: service_port
          }
        end
      end
    end
  end
end
