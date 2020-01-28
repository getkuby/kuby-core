module Kuby
  module Kubernetes
    class Ingress
      class Http
        extend ValueFields

        array_field(:path) { Path.new }

        def serialize
          { paths: paths.map(&:serialize) }
        end
      end
    end
  end
end
