# typed: strict

module Kuby
  module Docker
    class Alpine < Distro
      SHELL_EXE = T.let('/bin/sh'.freeze, String)

      DEFAULT_PACKAGES = T.let([
        [:ca_certificates, nil],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1'],
        [:c_toolchain, nil],
        [:tzdata, nil],
        [:git, nil]
      ].freeze, T::Array[[Symbol, T.nilable(String)]])

      sig { returns(Layer) }
      attr_reader :phase

      sig { override.params(packages: T::Array[Distro::PackageImpl], into: Dockerfile).void }
      def install(packages, into:)
        dockerfile = into
        install_managed(packages, dockerfile)
        install_unmanaged(packages, dockerfile)
      end

      sig { override.returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages
        DEFAULT_PACKAGES
      end

      sig { override.returns(String) }
      def shell_exe
        SHELL_EXE
      end

      private

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_managed(packages, dockerfile)
        pkgs = T.cast(packages.select(&:managed?), T::Array[Distro::ManagedPackageImpl])

        unless pkgs.empty?
          package_names = pkgs.map { |pkg| pkg.package_name_for(:alpine) }
          dockerfile.run(
            "apk add --no-cache #{package_names.join(' ')}"
          )
        end
      end

      sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_unmanaged(packages, dockerfile)
        packages
          .reject(&:managed?)
          .each do |package|
            if package.respond_to?(:install_on_alpine)
              package.send(:install_on_alpine, dockerfile)
            else
              raise UnsupportedDistroError, "Couldn't install #{package.name} "\
                "because alpine is an unsupported distro"
            end
          end
      end
    end
  end
end
