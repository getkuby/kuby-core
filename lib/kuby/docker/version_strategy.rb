# typed: strict

module Kuby
  module Docker
    class VersionStrategy
      extend T::Sig

      sig { params(image: Image).void }
      def initialize(image)
        raise NotImplementedError, 'please use a Docker::VersionStrategy subclass'
      end

      sig { returns(ImageVersion) }
      def new_version
        raise NotImplementedError, 'please use a Docker::VersionStrategy subclass'
      end

      sig { returns(ImageVersion) }
      def current_version
        raise NotImplementedError, 'please use a Docker::VersionStrategy subclass'
      end

      sig { params(current_tag: T.nilable(String)).returns(ImageVersion) }
      def previous_version(current_tag = nil)
        raise NotImplementedError, 'please use a Docker::VersionStrategy subclass'
      end

      sig { params(tag: String).returns(T::Boolean) }
      def tag_exists?(tag)
        raise NotImplementedError, 'please use a Docker::VersionStrategy subclass'
      end
    end
  end
end
