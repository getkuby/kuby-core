# typed: strict

module Kuby
  module Docker
    class AssetsPhase < Layer
      extend T::Sig

      sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        dockerfile.run(
          'bundle', 'exec', 'rake', 'webpacker:install'
        )

        dockerfile.run(
          'bundle', 'exec', 'rake', 'assets:precompile'
        )
      end
    end
  end
end
