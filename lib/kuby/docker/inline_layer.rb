module Kuby
  module Docker
    class InlineLayer < Layer
      attr_reader :block

      def initialize(block)
        @block = block
      end

      def apply_to(dockerfile)
        block.call(dockerfile)
      end
    end
  end
end
