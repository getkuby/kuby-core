# typed: strict

module Kuby
  module Docker
    class CopyPhase < Layer
      extend T::Sig

      DEFAULT_PATHS = T.let(['./'].freeze, T::Array[String])

      sig { returns(T::Array[String]) }
      attr_reader :paths

      sig { params(environment: Environment).void }
      def initialize(environment)
        super
        @paths = T.let([], T::Array[String])
      end

      sig { params(path: String).void }
      def <<(path)
        paths << path
      end

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        to_copy = paths.empty? ? DEFAULT_PATHS : paths
        to_copy.each { |path| dockerfile.copy(path, '.') }
      end
    end
  end
end
