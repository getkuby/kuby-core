module Kuby
  module Docker
    class Phase
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end

      private

      def app
        definition.app
      end

      def metadata
        definition.docker.metadata
      end
    end
  end
end
