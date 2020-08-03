module Kuby
  module Docker
    class Alpine
      SHELL_EXE = '/bin/sh'.freeze

      DEFAULT_PACKAGES = [
        [:ca_certificates],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1'],
        [:c_toolchain],
        [:tzdata]
      ].freeze

      attr_reader :phase

      def initialize(phase)
        @phase = phase
      end

      def install(packages, into:)
        dockerfile = into
        install_managed(packages, dockerfile)
        install_unmanaged(packages, dockerfile)
      end

      def default_packages
        DEFAULT_PACKAGES
      end

      def shell_exe
        SHELL_EXE
      end

      private

      def install_managed(packages, dockerfile)
        pkgs = packages.select(&:managed?)

        unless pkgs.empty?
          package_names = pkgs.map { |pkg| pkg.package_name_for(:alpine) }
          dockerfile.run(
            "apk add --no-cache #{package_names.join(' ')}"
          )
        end
      end

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
