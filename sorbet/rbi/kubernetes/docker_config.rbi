# typed: true

module Kuby
  module Kubernetes
    class DockerConfig
      extend KubeDSL::ValueFields::ClassMethods
      include KubeDSL::ValueFields::InstanceMethods

      sig { params(val: T.nilable(String)).returns(String) }
      def registry_host(val = nil)
      end

      sig { params(val: T.nilable(String)).returns(String) }
      def username(val = nil)
      end

      sig { params(val: T.nilable(String)).returns(String) }
      def password(val = nil)
      end

      sig { params(val: T.nilable(String)).returns(String) }
      def email(val = nil)
      end
    end
  end
end
