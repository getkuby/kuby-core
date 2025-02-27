# typed: strict

module Kuby
  module Docker
    class AppPhase < Layer
      extend T::Sig

      T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        super

        @env_vars = T.let({}, T::Hash[String, String])
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        @env_vars.each_pair do |key, value|
          dockerfile.env("#{key}='#{value}'")
        end

        absolute_app_root = Pathname(T.must(dockerfile.current_workdir))
          .join(environment.docker.app_root_path)
          .to_s

        if dockerfile.current_workdir != absolute_app_root
          dockerfile.workdir(absolute_app_root)
        end
      end

      T::Sig::WithoutRuntime.sig { params(key: String, value: String).void }
      def env(key, value)
        @env_vars[key] = value
      end
    end
  end
end
