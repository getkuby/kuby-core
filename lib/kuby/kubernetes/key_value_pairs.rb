module Kuby
  module Kubernetes
    class KeyValuePairs
      def method_missing(method_name, *args)
        kv_class.value_fields(method_name)
        kv_fields << method_name
        kv_instance.send(method_name, *args)
      end

      def serialize
        kv_fields.each_with_object({}) do |field, ret|
          ret[field] = kv_instance.send(field)
        end
      end

      private

      def kv_fields
        @kv_fields ||= []
      end

      def kv_class
        @kv_class ||= Class.new do
          extend ValueFields
        end
      end

      def kv_instance
        @kv_instance ||= kv_class.new
      end
    end
  end
end
