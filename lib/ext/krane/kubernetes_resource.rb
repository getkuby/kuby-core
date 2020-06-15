require 'krane/kubernetes_resource'

# See: https://github.com/Shopify/krane/pull/720
module Krane
  class KubernetesResource
    class << self
      def class_for_kind(kind)
        if Krane.const_defined?(kind, false)
          Krane.const_get(kind, false)
        end
      rescue NameError
        nil
      end
    end
  end
end
