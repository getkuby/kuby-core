module Kuby
  module Docker
    class Debian
      SHELL_EXE = '/bin/bash'

      DEFAULT_PACKAGES = [
        [:ca_certificates],
        [:nodejs, '12.14.1'],
        [:yarn, '1.21.1']
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
