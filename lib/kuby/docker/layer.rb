# typed: strict

module Kuby
  module Docker
    class Layer
      extend T::Sig
      extend T::Helpers

      abstract!

      T::Sig::WithoutRuntime.sig { returns(Environment) }
      attr_reader :environment

      T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        @environment = environment
      end

      T::Sig::WithoutRuntime.sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end
    end
  end
end
