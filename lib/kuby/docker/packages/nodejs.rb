module Kuby
  module Docker
    module Packages
      class Nodejs < Package
        def install_on_debian(dockerfile)
          install_from_image("node:#{version}", dockerfile)
        end

        def install_on_alpine(dockerfile)
          install_from_image("node:#{version}-alpine", dockerfile)
        end

        def version
          @version || 'current'
        end

        private

        def install_from_image(image, dockerfile)
          dockerfile.insert_at(0) do
            dockerfile.from(image, as: 'nodejs')
          end

          dockerfile.copy('/usr/local/bin/node', '/usr/local/bin/node', from: 'nodejs')
        end
      end
    end
  end
end
