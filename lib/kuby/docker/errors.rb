module Kuby
  module Docker
    class BuildError < StandardError; end
    class PushError < StandardError; end

    class MissingTagError < StandardError
      attr_reader :tag

      def initialize(tag)
        @tag = tag
      end

      def message
        @message ||= "Could not find tag '#{tag}'."
      end
    end
  end
end
