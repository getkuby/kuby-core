module Kuby
  module Kubernetes
    class KeyValuePairs
      def initialize(*)
        @fields = []

        @klass = Class.new do
          extend ValueFields
        end

        @instance = @klass.new
      end

      def method_missing(method_name, *args)
        @klass.value_fields method_name
        @fields << method_name
        @instance.send(method_name, *args)
      end

      def serialize
        @fields.each_with_object({}) do |field, ret|
          ret[field] = @instance.send(field)
        end
      end
    end
  end
end
