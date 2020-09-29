# typed: strict

module Kuby
  module Docker
    class BuildError < StandardError; end
    class PushError < StandardError; end
    class PullError < StandardError; end
    class LoginError < StandardError; end

    class MissingTagError < StandardError
      extend T::Sig

      sig { returns(String) }
      attr_reader :tag

      sig { params(tag: String).void }
      def initialize(tag)
        @tag = tag
        @message = T.let(@message, T.nilable(String))
      end

      sig { returns(String) }
      def message
        @message ||= "Could not find tag '#{tag}'."
      end
    end

    class UnsupportedDistroError < StandardError; end
    class MissingPackageError < StandardError; end
    class MissingDistroError < StandardError; end
  end
end
