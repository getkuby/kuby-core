# typed: strict

module Kuby
  module Docker
    class Distro
      extend T::Sig
      extend T::Helpers

      abstract!

      PackageImpl = T.type_alias {
        T.any(Packages::Package, Packages::ManagedPackage, Packages::SimpleManagedPackage)
      }

      ManagedPackageImpl = T.type_alias {
        T.any(Packages::ManagedPackage, Packages::SimpleManagedPackage)
      }

      T::Sig::WithoutRuntime.sig { params(phase: Layer).void }
      def initialize(phase)
        @phase = phase
      end

      T::Sig::WithoutRuntime.sig { params(packages: T::Array[PackageImpl], into: Dockerfile).void }
      def install(packages, into:)
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      T::Sig::WithoutRuntime.sig { returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def shell_exe
        raise NotImplementedError,
          "#{__method__} must be defined in derived classes"
      end
    end
  end
end
