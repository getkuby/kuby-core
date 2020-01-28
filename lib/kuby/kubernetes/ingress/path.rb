module Kuby
  module Kubernetes
    class Ingress
      class Path
        extend ValueFields

        object_field(:backend) { Backend.new }

        def serialize
          { backend: backend.serialize }
        end
      end
    end
  end
end
