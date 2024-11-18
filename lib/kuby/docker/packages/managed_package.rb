# typed: strict

module Kuby
  module Docker
    module Packages
      class ManagedPackage
        # extend T::Sig

        # T::Sig::WithoutRuntime.sig { returns(Symbol) }
        attr_reader :name

        # T::Sig::WithoutRuntime.sig { returns(T::Hash[Symbol, String]) }
        attr_reader :names_per_distro

        # T::Sig::WithoutRuntime.sig {
        #   params(
        #     name: Symbol,
        #     names_per_distro: T::Hash[Symbol, String]
        #   )
        #   .void
        # }
        def initialize(name, names_per_distro)
          @name = name
          @names_per_distro = names_per_distro
        end

        # T::Sig::WithoutRuntime.sig { params(distro: Symbol).returns(String) }
        def package_name_for(distro)
          names_per_distro.fetch(distro) do
            raise UnsupportedDistroError, "Couldn't install #{name} "\
              "because #{distro} is an unsupported distro"
          end
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
