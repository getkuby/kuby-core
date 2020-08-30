module Kuby
  module Docker
    class Layer
      attr_reader :environment

      def initialize(environment)
        @environment = environment
      end

      def apply_to(dockerfile)
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      private

      def metadata
        environment.docker.metadata
      end
    end
  end
end
