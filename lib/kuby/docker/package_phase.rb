module Kuby
  module Docker
    class PackagePhase < Phase
      class Debian
        attr_reader :phase

        def initialize(phase)
          @phase = phase
        end

        def apply_to(dockerfile)
          if phase.packages.include?('nodejs')
            dockerfile.run('curl -sSL https://deb.nodesource.com/setup_12.x | bash')
          end

          if phase.packages.include?('yarn')
            dockerfile.run(<<~CMD.strip)
              curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
                echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list
            CMD
          end

          pkg_cmd = <<~CMD.strip
            apt-get update -qq && \
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-transport-https && \\
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-utils && \\
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends
          CMD

          unless phase.packages.empty?
            pkg_cmd << " \\\n  #{phase.packages.join("\\\n  ")}"
          end

          dockerfile.run(pkg_cmd)
        end
      end

      DEFAULT_DISTRO = :debian
      DEFAULT_PACKAGES = ['ca-certificates', 'nodejs', 'yarn'].freeze

      DISTRO_MAP = { debian: Debian }.freeze

      attr_accessor :distro
      attr_reader :packages

      def initialize(*args)
        super
        @packages = DEFAULT_PACKAGES.dup
      end

      def <<(package)
        @packages << package
      end

      def apply_to(dockerfile)
        dist = distro || DEFAULT_DISTRO
        dist_class = DISTRO_MAP[dist]
        raise "No distro named #{dist}" unless dist_class

        dist_class.new(self).apply_to(dockerfile)
      end
    end
  end
end
