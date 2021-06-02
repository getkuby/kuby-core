# typed: strict

module Kuby
  module Docker
    class BuildError < StandardError; end
    class PushError < StandardError; end
    class PullError < StandardError; end
    class LoginError < StandardError; end
    class MissingTagError < StandardError; end
    class UnsupportedDistroError < StandardError; end
    class MissingPackageError < StandardError; end
    class MissingDistroError < StandardError; end
  end
end
