# typed: strict

module Kuby
  module Docker
    module Packages
      class Package
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { returns(Symbol) }
        attr_reader :name

        sig { returns(T.nilable(String)) }
        attr_reader :version

        sig { params(name: Symbol, version: T.nilable(String)).void }
        def initialize(name, version = nil)
          @name = name
          @version = version
        end

        sig { params(ver: String).returns(T.self_type) }
        def with_version(ver)
          self.class.new(name, ver)
        end

        sig { returns(T::Boolean) }
        def managed?
          false
        end
      end
    end
  end
end
