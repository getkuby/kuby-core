module Kuby
  module Docker
    class AssetsPhase < Layer
      def apply_to(dockerfile)
        dockerfile.run(
          'bundle', 'exec', 'rake', 'assets:precompile'
        )
      end
    end
  end
end
