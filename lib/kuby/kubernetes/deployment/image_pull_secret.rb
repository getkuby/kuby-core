module Kuby
  module Kubernetes
    class Deployment
      class ImagePullSecret
        extend ValueFields

        value_fields :name

        def serialize
          { name: name }
        end
      end
    end
  end
end
