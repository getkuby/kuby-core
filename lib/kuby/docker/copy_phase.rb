module Kuby
  module Docker
    class CopyPhase < Phase
      DEFAULT_PATHS = ['./'].freeze

      attr_reader :paths

      def initialize(*args)
        super
        @paths = []
      end

      def <<(path)
        paths << path
      end

      def apply_to(dockerfile)
        to_copy = paths.empty? ? DEFAULT_PATHS : paths
        to_copy.each { |path| dockerfile.copy(path, '.') }
      end
    end
  end
end
