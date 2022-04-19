# typed: strict

require 'pathname'

module Kuby
  module Docker
    class BundlerPhase < Layer
      extend T::Sig

      DEFAULT_GEMFILE = T.let('Gemfile'.freeze, String)
      DEFAULT_WITHOUT = T.let(
        ['development', 'test', 'deploy'].freeze, T::Array[String]
      )

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :version

      T::Sig::WithoutRuntime.sig { params(version: String).returns(String) }
      attr_writer :version

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :gemfile

      T::Sig::WithoutRuntime.sig { params(gemfile: String).returns(String) }
      attr_writer :gemfile

      T::Sig::WithoutRuntime.sig { returns(T.nilable(T::Array[String])) }
      attr_reader :without

      T::Sig::WithoutRuntime.sig { params(without: T::Array[String]).returns(T::Array[String]) }
      attr_writer :without

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :executable

      T::Sig::WithoutRuntime.sig { params(executable: String).returns(String) }
      attr_writer :executable

      T::Sig::WithoutRuntime.sig { params(environment: Environment).void }
      def initialize(environment)
        super

        @version = T.let(@version, T.nilable(String))
        @gemfile = T.let(@gemfile, T.nilable(String))
        @gemfiles = T.let([], T::Array[String])
        @without = T.let(@without, T.nilable(T::Array[String]))
        @executable = T.let(@executable, T.nilable(String))
      end

      T::Sig::WithoutRuntime.sig { override.params(dockerfile: Dockerfile).void }
      def apply_to(dockerfile)
        gf = gemfile || DEFAULT_GEMFILE
        lf = "#{gf}.lock"
        v = version || default_version
        wo = without || DEFAULT_WITHOUT

        host_path = Pathname(environment.docker.app_root_path)
        container_path = Pathname(dockerfile.current_workdir).join(environment.docker.app_root_path)

        dockerfile.run('gem', 'install', 'bundler', '-v', v)

        dockerfile.copy(host_path.join(gf), container_path.join(gf))
        dockerfile.copy(host_path.join(lf), container_path.join(lf))
        @gemfiles.each do |file|
          dockerfile.copy(host_path.join(file), container_path.join(file))
          extra_lf = host_path.join("#{file}.lock")

          if extra_lf.exist?
            dockerfile.copy(extra_lf, container_path.join("#{file}.lock"))
          end
        end

        dockerfile.env("BUNDLE_GEMFILE=#{container_path.join(gf)}")

        unless wo.empty?
          dockerfile.env("BUNDLE_WITHOUT='#{wo.join(' ')}'")
        end

        dockerfile.run(
          executable || 'bundle', 'lock', '--lockfile', container_path.join(lf)
        )

        dockerfile.run(
          executable || 'bundle', 'install',
          '--jobs', '$(nproc)',
          '--retry', '3'
        )

        # generate binstubs and add the bin directory to our path
        dockerfile.run(executable || 'bundle', 'binstubs', '--all')
        dockerfile.env("PATH=#{container_path.join('bin')}:$PATH")
      end

      T::Sig::WithoutRuntime.sig { params(paths: String).void }
      def gemfiles(*paths)
        @gemfiles.concat(paths)
      end

      private

      T::Sig::WithoutRuntime.sig { returns(String) }
      def default_version
        Bundler::VERSION
      end
    end
  end
end
