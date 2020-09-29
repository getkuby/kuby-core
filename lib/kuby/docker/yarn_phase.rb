# typed: strict

module Kuby
  module Docker
    class YarnPhase < Layer
      extend T::Sig

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        dockerfile.copy('package.json', '.')
        dockerfile.copy('yarn.lock*', '.')
        dockerfile.run('yarn', 'install')
      end
    end
  end
end
