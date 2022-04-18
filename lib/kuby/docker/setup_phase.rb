# typed: strict

module Kuby
  module Docker
    class SetupPhase < Layer
      extend T::Sig

      DEFAULT_WORKING_DIR = T.let('/usr/src/app'.freeze, String)

      T::Sig::WithoutRuntime.sig { params(base_image: String).returns(String) }
      attr_writer :base_image

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :working_dir

      T::Sig::WithoutRuntime.sig { params(working_dir: String).returns(String) }
      attr_writer :working_dir

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :rails_env

      T::Sig::WithoutRuntime.sig { params(rails_env: String).returns(String) }
      attr_writer :rails_env

      T::Sig::WithoutRuntime.sig { returns(Docker::Spec) }
      attr_reader :docker_spec

      T::Sig::WithoutRuntime.sig { params(environment: Environment, docker_spec: Docker::Spec).void }
      def initialize(environment, docker_spec)
        super(environment)

        @base_image = T.let(@base_image, T.nilable(String))
        @working_dir = T.let(@working_dir, T.nilable(String))
        @rails_env = T.let(@rails_env, T.nilable(String))
        @docker_spec = T.let(docker_spec, Docker::Spec)
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        dockerfile.from(base_image)
        dockerfile.workdir(working_dir || DEFAULT_WORKING_DIR)
        dockerfile.env("RAILS_ENV=#{rails_env || Kuby.env}")
        dockerfile.env("KUBY_ENV=#{Kuby.env}")
        dockerfile.arg('RAILS_MASTER_KEY')
      end

      T::Sig::WithoutRuntime.sig { returns(String) }
      def base_image
        @base_image || default_base_image
      end

      private

      T::Sig::WithoutRuntime.sig { returns(String) }
      def default_base_image
        case docker_spec.distro_name
          when :debian
            "ruby:#{RUBY_VERSION}"
          when :alpine
            "ruby:#{RUBY_VERSION}-alpine"
          else
            raise MissingDistroError, "distro '#{docker_spec.distro_name}' hasn't been registered"
        end
      end
    end
  end
end
