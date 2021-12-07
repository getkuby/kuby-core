# typed: strict

module Kuby
  module Docker
    class Spec
      extend T::Sig

      DEFAULT_DISTRO = :debian

      sig { returns(Environment) }
      attr_reader :environment

      sig { returns(T.nilable(String)) }
      attr_reader :image_url_str

      sig { returns(T.nilable(String)) }
      attr_reader :registry_metadata_url_str

      sig { params(environment: Environment).void }
      def initialize(environment)
        @environment = environment

        @credentials = T.let(@credentials, T.nilable(Credentials))
        @setup_phase = T.let(@setup_phase, T.nilable(SetupPhase))
        @package_phase = T.let(@package_phase, T.nilable(PackagePhase))
        @bundler_phase = T.let(@bundler_phase, T.nilable(BundlerPhase))
        @yarn_phase = T.let(@yarn_phase, T.nilable(YarnPhase))
        @copy_phase = T.let(@copy_phase, T.nilable(CopyPhase))
        @assets_phase = T.let(@assets_phase, T.nilable(AssetsPhase))
        @webserver_phase = T.let(@webserver_phase, T.nilable(WebserverPhase))

        @distro_name = T.let(@distro_name, T.nilable(Symbol))
        @distro_spec = T.let(@distro_spec, T.nilable(Distro))
        @layer_stack = T.let(@layer_stack, T.nilable(Kuby::Docker::LayerStack))

        @image_url_str = T.let(@image_url_str, T.nilable(String))
        @registry_metadata_url_str = T.let(@registry_metadata_url_str, T.nilable(String))
        @image = T.let(@image, T.nilable(Docker::AppImage))
      end

      sig { returns(Symbol) }
      def distro_name
        @distro_name || DEFAULT_DISTRO
      end

      sig { params(image_url: String).void }
      def base_image(image_url)
        setup_phase.base_image = image_url
      end

      sig { params(dir: String).void }
      def working_dir(dir)
        setup_phase.working_dir = dir
      end

      sig { params(env: String).void }
      def rails_env(env)
        setup_phase.rails_env = env
      end

      sig { params(version: String).void }
      def bundler_version(version)
        bundler_phase.version = version
      end

      sig { params(path: String).void }
      def gemfile(path)
        bundler_phase.gemfile = path
      end

      sig {
        params(
          package_name: Symbol,
          version: T.nilable(String)
        )
        .void
      }
      def package(package_name, version = nil)
        package_phase.add(package_name, version)
      end

      sig { params(distro_name: Symbol).void }
      def distro(distro_name)
        @distro_name = distro_name
        @distro_spec = nil
      end

      sig { params(path: String).void }
      def files(path)
        copy_phase << path
      end

      sig { params(port: Integer).void }
      def port(port)
        webserver_phase.port = port
      end

      sig { params(url: String).void }
      def image_url(url)
        @image_url_str = url
      end

      sig { params(url: String).void }
      def registry_metadata_url(url)
        @registry_metadata_url_str = url
      end

      sig {
        params(
          name: Symbol,
          layer: T.nilable(Layer),
          block: T.nilable(T.proc.params(df: Dockerfile).void)
        )
        .void
      }
      def use(name, layer = nil, &block)
        layer_stack.use(name, layer, &block)
      end

      sig {
        params(
          name: Symbol,
          layer: T.nilable(T.any(Layer, T::Hash[Symbol, T.untyped])),
          options: T::Hash[Symbol, T.untyped],
          block: T.nilable(T.proc.params(df: Dockerfile).void)
        )
        .void
      }
      def insert(name, layer = nil, options = {}, &block)
        layer_stack.insert(name, layer, options, &block)
      end

      sig { params(name: Symbol).void }
      def delete(name)
        layer_stack.delete(name)
      end

      sig { params(name: Symbol).returns(T::Boolean) }
      def exists?(name)
        layer_stack.includes?(name)
      end

      sig {
        params(block: T.nilable(T.proc.void)).returns(Credentials)
      }
      def credentials(&block)
        @credentials ||= Credentials.new
        @credentials.instance_eval(&block) if block
        @credentials
      end

      sig { returns(Docker::AppImage) }
      def image
        @image ||= begin
          dockerfile = Dockerfile.new.tap do |df|
            layer_stack.each { |layer| layer.apply_to(df) }
          end

          Docker::AppImage.new(
            dockerfile, T.must(image_url_str), credentials, registry_metadata_url_str
          )
        end
      end

      sig { returns(SetupPhase) }
      def setup_phase
        @setup_phase ||= SetupPhase.new(environment, self)
      end

      sig { returns(PackagePhase) }
      def package_phase
        @package_phase ||= PackagePhase.new(environment)
      end

      sig { returns(BundlerPhase) }
      def bundler_phase
        @bundler_phase ||= BundlerPhase.new(environment)
      end

      sig { returns(YarnPhase) }
      def yarn_phase
        @yarn_phase ||= YarnPhase.new(environment)
      end

      sig { returns(CopyPhase) }
      def copy_phase
        @copy_phase ||= CopyPhase.new(environment)
      end

      sig { returns(AssetsPhase) }
      def assets_phase
        @assets_phase ||= AssetsPhase.new(environment)
      end

      sig { returns(WebserverPhase) }
      def webserver_phase
        @webserver_phase ||= WebserverPhase.new(environment)
      end

      sig { returns(Distro) }
      def distro_spec
        @distro_spec ||= if distro_klass = Kuby.distros[distro_name]
          distro_klass.new(self)
        else
          raise MissingDistroError, "distro '#{distro_name}' hasn't been registered"
        end
      end

      private

      sig { returns(Kuby::Docker::LayerStack) }
      def layer_stack
        @layer_stack ||= Kuby::Docker::LayerStack.new.tap do |stack|
          stack.use(:setup_phase, setup_phase)
          stack.use(:package_phase, package_phase)
          stack.use(:bundler_phase, bundler_phase)
          stack.use(:yarn_phase, yarn_phase)
          stack.use(:copy_phase, copy_phase)
          stack.use(:assets_phase, assets_phase)
          stack.use(:webserver_phase, webserver_phase)
        end
      end
    end
  end
end
