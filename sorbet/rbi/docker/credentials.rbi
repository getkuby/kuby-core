# typed: strict

module Kuby
  module Docker
    class Credentials
      extend KubeDSL::ValueFields::ClassMethods
      include KubeDSL::ValueFields::InstanceMethods

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