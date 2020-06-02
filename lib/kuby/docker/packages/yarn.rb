module Kuby
  module Docker
    module Packages
      class Yarn < Package
        def install_on_debian(dockerfile)
          dockerfile.run(<<~CMD.strip)
            wget #{url} && \\
              yarnv=$(basename $(ls yarn-*.tar.gz | cut -d'-' -f 2) .tar.gz) && \\
              tar zxvf yarn-$yarnv.tar.gz -C /opt && \\
              mv /opt/yarn-$yarnv /opt/yarn && \\
              apt-get install -qq -y --no-install-recommends gnupg && \\
              wget -qO- https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --import && \\
              wget https://github.com/yarnpkg/yarn/releases/download/$yarnv/yarn-$yarnv.tar.gz.asc && \\
              gpg --verify yarn-$yarnv.tar.gz.asc
          CMD

          dockerfile.env("PATH=$PATH:/opt/yarn/bin")
        end

        def install_on_alpine(dockerfile)
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

        private

        def url
          @url ||= if version
            "https://github.com/yarnpkg/yarn/releases/download/v#{version}/yarn-v#{version}.tar.gz"
          else
            "https://yarnpkg.com/latest.tar.gz"
          end
        end
      end
    end
  end
end
