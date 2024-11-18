# typed: strict

module Kuby
  module Docker
    class Debian < Distro
      SHELL_EXE = '/bin/bash'.freeze

      DEFAULT_PACKAGES = [
        [:ca_certificates, nil],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1']
      ].freeze

      # T::Sig::WithoutRuntime.sig { returns(Layer) }
      attr_reader :phase

      # T::Sig::WithoutRuntime.sig { override.params(packages: T::Array[Distro::PackageImpl], into: Dockerfile).void }
      def install(packages, into:)
        dockerfile = into
        install_managed(packages, dockerfile)
        install_unmanaged(packages, dockerfile)
      end

      # T::Sig::WithoutRuntime.sig { override.returns(T::Array[[Symbol, T.nilable(String)]]) }
      def default_packages
        DEFAULT_PACKAGES
      end

      # T::Sig::WithoutRuntime.sig { override.returns(String) }
      def shell_exe
        SHELL_EXE
      end

      private

      # T::Sig::WithoutRuntime.sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_managed(packages, dockerfile)
        pkgs = packages.select(&:managed?)

        pkg_cmd = <<~CMD.strip
          apt-get update -qq && \\
            DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-transport-https && \\
            DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-utils && \\
            DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends
        CMD

        unless pkgs.empty?
          package_names = pkgs.map { |pkg| pkg.package_name_for(:debian) }
          pkg_cmd << " \\\n  #{package_names.join(" \\\n  ")}"
        end

        dockerfile.run(pkg_cmd)
      end

      # T::Sig::WithoutRuntime.sig { params(packages: T::Array[Distro::PackageImpl], dockerfile: Dockerfile).void }
      def install_unmanaged(packages, dockerfile)
        packages
          .reject(&:managed?)
          .each do |package|
            if package.respond_to?(:install_on_debian)
              package.send(:install_on_debian, dockerfile)
            else
              raise UnsupportedDistroError, "Couldn't install #{package.name} "\
                "because debian is an unsupported distro"
            end
          end
      end
    end
  end
end
