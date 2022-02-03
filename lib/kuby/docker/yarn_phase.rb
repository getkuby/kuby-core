# typed: strict

module Kuby
  module Docker
    class YarnPhase < Layer
      extend T::Sig

      sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        host_path = environment.docker.app_root_path
        container_path = Pathname(dockerfile.current_workdir).join(
          environment.docker.app_root_path
        )

        # use brackets as a hack to only copy the files if they exist
        dockerfile.copy(
          "#{host_path}/package.json #{host_path}/yarn.loc[k] #{host_path}/.npmr[c] #{host_path}/.yarnr[c]",
          container_path
        )

        dockerfile.run('yarn', 'install', '--cwd', container_path)
      end
    end
  end
end
