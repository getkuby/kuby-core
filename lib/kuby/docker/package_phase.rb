# typed: strict

module Kuby
  module Docker
    class PackagePhase < Layer
      extend T::Sig

      Operation = T.type_alias { [Symbol, Symbol, T.nilable(String)] }

      T::Sig::WithoutRuntime.sig { returns(T::Array[Operation]) }
      attr_reader :operations

      T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        super

        @operations = T.let([], T::Array[Operation])
      end

      T::Sig::WithoutRuntime.sig { params(package_name: Symbol, version: T.nilable(String)).void }
      def add(package_name, version = nil)
        operations << [:add, package_name, version]
      end

      T::Sig::WithoutRuntime.sig { params(package_name: Symbol).void }
      def remove(package_name)
        operations << [:remove, package_name, nil]
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        packages = distro_spec.default_packages.dup

        operations.each do |operator, package_name, version|
          if operator == :add
            packages << [package_name, version]
          else
            packages.reject! do |pkg_name_to_del, *|
              pkg_name_to_del == package_name
            end
          end
        end

        package_impls = packages.map do |package_name, version|
          get_package(package_name, version)
        end

        distro_spec.install(package_impls, into: dockerfile)
      end

      private

      T::Sig::WithoutRuntime.sig { returns(Distro) }
      def distro_spec
        environment.docker.distro_spec
      end

      T::Sig::WithoutRuntime.sig {
        params(
          package_name: Symbol,
          version: T.nilable(String)
        )
        .returns(Distro::PackageImpl)
      }
      def get_package(package_name, version)
        if package = Kuby.packages[package_name]
          package.with_version(version)
        else
          raise MissingPackageError, "package '#{package_name}' hasn't been registered"
        end
      end
    end
  end
end
