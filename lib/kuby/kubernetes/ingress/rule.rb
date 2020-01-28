module Kuby
  module Kubernetes
    class Ingress
      class Rule
        extend ValueFields

        value_field :host
        object_field(:http) { Http.new }

        def serialize
          {
            host: host,
            http: http.serialize
          }
        end
      end
    end
  end
end
