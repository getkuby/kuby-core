# typed: strict

module Kuby
  module Docker
    module Packages
      class SimpleManagedPackage
        # extend T::Sig

        # T::Sig::WithoutRuntime.sig { returns(String) }
        attr_reader :name

        # T::Sig::WithoutRuntime.sig { params(name: T.any(String, Symbol)).void }
        def initialize(name)
          @name = name.to_s
        end

        # T::Sig::WithoutRuntime.sig { params(distro: Symbol).returns(String) }
        def package_name_for(distro)
          name
        end

        # T::Sig::WithoutRuntime.sig { params(ver: String).returns(T.self_type) }
        def with_version(ver)
          self
        end

        # T::Sig::WithoutRuntime.sig { returns(T::Boolean) }
        def managed?
          true
        end
      end
    end
  end
end
