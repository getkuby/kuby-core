# typed: strict

module Kuby
  module Docker
    class YarnPhase < Layer
      extend T::Sig

      T::Sig::WithoutRuntime.sig { params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        host_path = environment.docker.app_root_path

        # if more than one file is passed to the COPY directive, the destination must be
        # a directory and must end with a slash
        container_path = ensure_trailing_delimiter(
          File.join(
            dockerfile.current_workdir,
            environment.docker.app_root_path
          )
        )

        if File.exist?(File.join(host_path, 'package.json'))
          # use brackets as a hack to only copy the files if they exist
          dockerfile.copy(
            "#{host_path}/package.json #{host_path}/yarn.loc[k] #{host_path}/.npmr[c] #{host_path}/.yarnr[c]",
            container_path
          )

          dockerfile.run('yarn', 'install', '--cwd', container_path)
        end
      end

      private

      T::Sig::WithoutRuntime.sig { params(path: String).returns(String) }
      def ensure_trailing_delimiter(path)
        path.end_with?(File::SEPARATOR) ? path : File.join(path, '')
      end
    end
  end
end
