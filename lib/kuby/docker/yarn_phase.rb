# typed: strict

module Kuby
  module Docker
    class YarnPhase < Layer
      extend T::Sig

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        # use character classes as a hack to only copy the files if they exist
        dockerfile.copy('package.json yarn.loc[k] .npmr[c] .yarnr[c]', './')
        dockerfile.run('yarn', 'install')
      end
    end
  end
end
