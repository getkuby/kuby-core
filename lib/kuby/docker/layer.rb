module Kuby
  module Docker
    class Layer
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end

      def apply_to(dockerfile)
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      private

      def metadata
        definition.docker.metadata
      end
    end
  end
end
