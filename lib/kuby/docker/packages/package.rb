# typed: strict

module Kuby
  module Docker
    module Packages
      class Package
        extend T::Sig
        extend T::Helpers

        abstract!

        T::Sig::WithoutRuntime.sig { returns(Symbol) }
        attr_reader :name

        T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
        attr_reader :version

        T::Sig::WithoutRuntime.sig { params(name: Symbol, version: T.nilable(String)).void }
        def initialize(name, version = nil)
          @name = name
          @version = version
        end

        T::Sig::WithoutRuntime.sig { params(ver: String).returns(T.self_type) }
        def with_version(ver)
          self.class.new(name, ver)
        end

        T::Sig::WithoutRuntime.sig { returns(T::Boolean) }
        def managed?
          false
        end
      end
    end
  end
end
