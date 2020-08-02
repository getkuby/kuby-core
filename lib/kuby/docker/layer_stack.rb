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

      def use(name, layer = nil, &block)
        stack << name

        if layer
          layers[name] = layer
        elsif block_given?
          layers[name] = InlineLayer.new(block)
        else
          raise "Must either pass a layer object or a block to `#{__method__}'"
        end
      end

      def insert(name, layer = nil, options = {}, &block)
        # this is truly gross but it's the only way I can think of to be able
        # to call insert these two ways:
        #
        # insert :foo, FooLayer.new, before: :bundler_phase
        # insert :foo, before: :bundler_phase do
        #   ...
        # end
        if layer.is_a?(Hash)
          insert(name, nil, options.merge(layer), &block)
          return
        end

        existing_name = options[:before] || options[:after]
        idx = stack.index(existing_name)

        unless idx
          raise ArgumentError, "Could not find existing layer '#{existing_name}'"
        end

        idx += 1 if options[:after]
        stack.insert(idx, name)

        if layer
          layers[name] = layer
        elsif block_given?
          layers[name] = InlineLayer.new(block)
        else
          raise "Must either pass a layer object or a block to `#{__method__}'"
        end
      end

      def delete(name)
        stack.delete(name)
        layers.delete(name)
      end
    end
  end
end
