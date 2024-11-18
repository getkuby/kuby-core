# typed: strict

module Kuby
  module Docker
    class CopyPhase < Layer
      # extend T::Sig

      DEFAULT_PATHS = ['./'].freeze

      # T::Sig::WithoutRuntime.sig { returns(T::Array[String]) }
      attr_reader :paths

      # T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        super
        @paths = []
      end

      # T::Sig::WithoutRuntime.sig { params(path: String).void }
      def <<(path)
        paths << path
      end

      # T::Sig::WithoutRuntime.sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        to_copy = paths.empty? ? DEFAULT_PATHS : paths
        to_copy.each { |path| dockerfile.copy(path, '.') }
      end
    end
  end
end
