module Kuby
  module Docker
    class PackagePhase < Layer
      attr_reader :operations

      def initialize(*args)
        super

        @operations = []
      end

      def add(package_name, version = nil)
        operations << [:add, package_name, version]
      end

      def remove(package_name)
        operations << [:remove, package_name]
      end

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

        packages.map! do |package_name, version|
          get_package(package_name, version)
        end

        distro_spec.install(packages, into: dockerfile)
      end

      private

      def distro_spec
        environment.docker.distro_spec
      end

      def get_package(package_name, version)
        if package = Kuby.packages[package_name]
          package.with_version(version)
        else
          raise MissingPackageError, "package '#{package_name}' hasn't been registered"
        end
      end

      def metadata
        environment.docker.metadata
      end
    end
  end
end
