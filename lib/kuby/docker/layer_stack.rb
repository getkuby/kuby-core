module Kuby
  module Docker
    class LayerStack
      include Enumerable

      attr_reader :stack, :layers

      def initialize
        @stack = []
        @layers = {}
      end

      def each
        return to_enum(__method__) unless block_given?
        @stack.each { |name| yield layers[name] }
      end

      def use(name, layer)
        stack << name
        layers[name] = layer
      end

      def insert(name, layer, options = {})
        existing_name = options[:before] || options[:after]
        idx = stack.index(existing_name)

        unless idx
          raise ArgumentError, "Could not find existing layer '#{existing_name}'"
        end

        idx += 1 if options[:after]
        stack.insert(idx, name)
        layers[name] = layer
      end

      def delete(name)
        stack.delete(name)
        layers.delete(name)
      end
    end
  end
end
