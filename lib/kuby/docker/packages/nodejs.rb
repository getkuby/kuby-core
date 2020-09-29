# typed: strict

module Kuby
  module Docker
    module Packages
      class Nodejs < Package
        extend T::Sig

        sig { params(dockerfile: Dockerfile).void }
        def install_on_debian(dockerfile)
          install_from_image("node:#{version}", dockerfile)
        end

        sig { params(dockerfile: Dockerfile).void }
        def install_on_alpine(dockerfile)
          install_from_image("node:#{version}-alpine", dockerfile)
        end

        sig { returns(String) }
        def version
          @version || 'current'
        end

        private

        sig { params(image: String, dockerfile: Dockerfile).void }
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
