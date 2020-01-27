module Kuby
  module Kubernetes
    class ConfigMap
      extend ValueFields

      value_fields :name

      def initialize(&block)
        instance_eval(&block) if block
      end

      def serialize
        {
          name: name
        }
      end
    end
  end
end
