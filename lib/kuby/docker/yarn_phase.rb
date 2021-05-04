# typed: strict

module Kuby
  module Docker
    class YarnPhase < Layer
      extend T::Sig

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        dockerfile.copy('package.json', '.')
        # use character classes as a hack to only copy the files if they exist
        dockerfile.copy('yarn.loc[k]', '.')
        dockerfile.copy('.npmr[c]', '.')
        dockerfile.copy('.yarnr[c]', '.')
        dockerfile.run('yarn', 'install')
      end
    end
  end
end
