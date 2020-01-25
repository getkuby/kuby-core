module Kuby
  module Docker
    class PackagePhase < Phase
      class Package
        attr_reader :name, :version

        def initialize(name, version)
          @name = name
          @version = version
        end
      end

      class PackageList
        include Enumerable

        attr_reader :packages

        def initialize(package_tuples)
          @packages = []
          package_tuples.each { |pt| self.<<(*pt) }
        end

        def [](name)
          packages.find { |pkg| pkg.name == name }
        end

        def <<(name, version = nil)
          packages << Package.new(name, version)
        end

        def delete(name)
          packages.delete_if { |pkg| pkg.name == name }
        end

        def each(&block)
          packages.each(&block)
        end

        def empty?
          packages.empty?
        end
      end

      class Debian
        DEFAULT_PACKAGES = [
          ['ca-certificates'],
          ['nodejs', '12.14.1'],
          ['yarn', '1.21.1']
        ].freeze

        attr_reader :phase, :packages

        def initialize(phase)
          @phase = phase
          @packages = PackageList.new(DEFAULT_PACKAGES.dup)
        end

        def apply_to(dockerfile)
          to_install = packages.dup

          if nodejs = to_install['nodejs']
            install_nodejs(dockerfile, nodejs)
            to_install.delete('nodejs')
          end

          if yarn = to_install['yarn']
            install_yarn(dockerfile, yarn)
            to_install.delete('yarn')
          end

          pkg_cmd = <<~CMD.strip
            apt-get update -qq && \\
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-transport-https && \\
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends apt-utils && \\
              DEBIAN_FRONTEND=noninteractive apt-get install -qq -y --no-install-recommends
          CMD

          unless packages.empty?
            pkg_cmd << " \\\n  #{packages.map(&:name).join(" \\\n  ")}"
          end

          dockerfile.run(pkg_cmd)
        end

        private

        def install_nodejs(dockerfile, nodejs)
          dockerfile.insert_at(0) do
            version = nodejs.version || 'current'
            # no distro means debian, eg. stretch, buster, etc
            node_image = "node:#{version}"
            dockerfile.from(node_image, as: 'nodejs')
          end

          dockerfile.copy('/usr/local/bin/node', '/usr/local/bin/node', from: 'nodejs')
        end

        def install_yarn(dockerfile, yarn)
          url = if yarn.version
            "https://github.com/yarnpkg/yarn/releases/download/v#{yarn.version}/yarn-v#{yarn.version}.tar.gz"
          else
            "https://yarnpkg.com/latest.tar.gz"
          end

          dockerfile.run(<<~CMD.strip)
            wget #{url} && \\
              yarnv=$(basename $(ls yarn-*.tar.gz | cut -d'-' -f 2) .tar.gz) && \\
              tar zxvf yarn-$yarnv.tar.gz -C /opt && \\
              mv /opt/yarn-$yarnv /opt/yarn && \\
              wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --import && \\
              wget https://github.com/yarnpkg/yarn/releases/download/$yarnv/yarn-$yarnv.tar.gz.asc && \\
              gpg --verify yarn-$yarnv.tar.gz.asc
          CMD

          dockerfile.env("PATH=$PATH:/opt/yarn/bin")
        end
      end

      class Alpine
        DEFAULT_PACKAGES = [
          ['ca-certificates'],
          ['nodejs', '12.14.1'],
          ['yarn', '1.21.1'],
          ['build-base'],
          ['sqlite-dev'],
          ['tzdata']
        ].freeze

        attr_reader :phase, :packages

        def initialize(phase)
          @phase = phase
          @packages = PackageList.new(DEFAULT_PACKAGES.dup)
        end

        def apply_to(dockerfile)
          to_install = packages.dup

          if nodejs = to_install['nodejs']
            install_nodejs(dockerfile, nodejs)
            to_install.delete('nodejs')
          end

          if yarn = to_install['yarn']
            install_yarn(dockerfile, yarn)
            to_install.delete('yarn')
          end

          unless packages.empty?
            dockerfile.run(
              "apk add --no-cache #{packages.map(&:name).join(' ')}"
            )
          end
        end

        private

        def install_nodejs(dockerfile, nodejs)
          dockerfile.insert_at(0) do
            version = nodejs.version || 'current'
            node_image = "node:#{version}-alpine"
            dockerfile.from(node_image, as: 'nodejs')
          end

          dockerfile.copy('/usr/local/bin/node', '/usr/local/bin/node', from: 'nodejs')
        end

        def install_yarn(dockerfile, yarn)
          url = if yarn.version
            "https://github.com/yarnpkg/yarn/releases/download/v#{yarn.version}/yarn-v#{yarn.version}.tar.gz"
          else
            "https://yarnpkg.com/latest.tar.gz"
          end

          dockerfile.run(<<~CMD.strip)
            wget #{url} && \\
              yarnv=$(basename $(ls yarn-*.tar.gz | cut -d'-' -f 2) .tar.gz) && \\
              tar zxvf yarn-$yarnv.tar.gz -C /opt && \\
              mv /opt/yarn-$yarnv /opt/yarn && \\
              apk add --no-cache gnupg && \\
              wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --import && \\
              wget https://github.com/yarnpkg/yarn/releases/download/$yarnv/yarn-$yarnv.tar.gz.asc && \\
              gpg --verify yarn-$yarnv.tar.gz.asc
          CMD

          dockerfile.env("PATH=$PATH:/opt/yarn/bin")
        end

        def metadata
          phase.definition.docker.metadata
        end
      end

      DISTRO_MAP = { debian: Debian, alpine: Alpine }.freeze

      attr_reader :distro, :packages

      def initialize(*args)
        super
        @distro = DISTRO_MAP[metadata.distro].new(self)
      end

      def distro_updated
        dist_class = DISTRO_MAP[metadata.distro]
        raise "No distro named #{metadata.distro}" unless dist_class
        @distro = dist_class.new(self)
      end

      def <<(package)
        distro.packages << package
      end

      def apply_to(dockerfile)
        distro.apply_to(dockerfile)
      end
    end
  end
end
