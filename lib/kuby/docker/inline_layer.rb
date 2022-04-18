# typed: strict

module Kuby
  module Docker
    class InlineLayer < Layer
      extend T::Sig

      T::Sig::WithoutRuntime.sig { returns(T.proc.params(df: Dockerfile).void) }
      attr_reader :block

      T::Sig::WithoutRuntime.sig { params(block: T.proc.params(df: Dockerfile).void).void }
      def initialize(block)
        @block = block
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        block.call(dockerfile)
      end
    end
  end
end
