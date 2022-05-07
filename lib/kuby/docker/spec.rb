# typed: strict

module Kuby
  module Docker
    class Spec
      extend T::Sig

      DEFAULT_DISTRO = T.let(:debian, Symbol)
      DEFAULT_APP_ROOT_PATH = T.let('.'.freeze, String)

      T::Sig::WithoutRuntime.sig { returns(Kuby::Environment) }
      attr_reader :environment

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :image_url_str

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :registry_index_url_str

      T::Sig::WithoutRuntime.sig { returns(T.nilable(String)) }
      attr_reader :app_root_path

      T::Sig::WithoutRuntime.sig { returns T.nilable(Kuby::Docker::AppImage) }
      attr_reader :image

      T::Sig::WithoutRuntime.sig { params(environment: Kuby::Environment).void }
      def initialize(environment)
        @environment = environment

        @credentials = T.let(@credentials, T.nilable(Credentials))
        @setup_phase = T.let(@setup_phase, T.nilable(SetupPhase))
        @package_phase = T.let(@package_phase, T.nilable(PackagePhase))
        @bundler_phase = T.let(@bundler_phase, T.nilable(BundlerPhase))
        @yarn_phase = T.let(@yarn_phase, T.nilable(YarnPhase))
        @copy_phase = T.let(@copy_phase, T.nilable(CopyPhase))
        @app_phase = T.let(@app_phase, T.nilable(AppPhase))
        @assets_phase = T.let(@assets_phase, T.nilable(AssetsPhase))
        @webserver_phase = T.let(@webserver_phase, T.nilable(WebserverPhase))

        @distro_name = T.let(@distro_name, T.nilable(Symbol))
        @distro_spec = T.let(@distro_spec, T.nilable(Distro))
        @layer_stack = T.let(@layer_stack, T.nilable(Kuby::Docker::LayerStack))

        @image_url_str = T.let(@image_url_str, T.nilable(String))
        @registry_index_url_str = T.let(@registry_index_url_str, T.nilable(String))
        @image = T.let(@image, T.nilable(Docker::AppImage))

        @app_root_path = T.let(DEFAULT_APP_ROOT_PATH, String)
      end

      T::Sig::WithoutRuntime.sig { returns(Symbol) }
      def distro_name
        @distro_name || DEFAULT_DISTRO
      end

      T::Sig::WithoutRuntime.sig { params(image_url: String).void }
      def base_image(image_url)
        setup_phase.base_image = image_url
      end

      T::Sig::WithoutRuntime.sig { params(dir: String).void }
      def working_dir(dir)
        setup_phase.working_dir = dir
      end

      T::Sig::WithoutRuntime.sig { params(env: String).void }
      def rails_env(env)
        setup_phase.rails_env = env
      end

      T::Sig::WithoutRuntime.sig { params(version: String).void }
      def bundler_version(version)
        bundler_phase.version = version
      end

      T::Sig::WithoutRuntime.sig { params(path: String).void }
      def gemfile(path)
        bundler_phase.gemfile = path
      end

      T::Sig::WithoutRuntime.sig { params(path: String).void }
      def app_root(path)
        @app_root_path = path
      end

      T::Sig::WithoutRuntime.sig {
        params(
          package_name: Symbol,
          version: T.nilable(String)
        )
        .void
      }
      def package(package_name, version = nil)
        package_phase.add(package_name, version)
      end

      T::Sig::WithoutRuntime.sig { params(distro_name: Symbol).void }
      def distro(distro_name)
        @distro_name = distro_name
        @distro_spec = nil
      end

      T::Sig::WithoutRuntime.sig { params(path: String).void }
      def files(path)
        copy_phase << path
      end

      T::Sig::WithoutRuntime.sig { params(port: Integer).void }
      def port(port)
        webserver_phase.port = port
      end

      T::Sig::WithoutRuntime.sig { params(url: String).void }
      def image_url(url)
        @image_url_str = url
      end

      T::Sig::WithoutRuntime.sig { params(url: String).void }
      def registry_index_url(url)
        @registry_index_url_str = url
      end

      T::Sig::WithoutRuntime.sig {
        params(
          name: Symbol,
          layer: T.nilable(Layer),
          block: T.nilable(T.proc.params(df: Kuby::Docker::Dockerfile).void)
        )
        .void
      }
      def use(name, layer = nil, &block)
        layer_stack.use(name, layer, &block)
      end

      T::Sig::WithoutRuntime.sig {
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

      T::Sig::WithoutRuntime.sig { params(name: Symbol).void }
      def delete(name)
        layer_stack.delete(name)
      end

      T::Sig::WithoutRuntime.sig { params(name: Symbol).returns(T::Boolean) }
      def exists?(name)
        layer_stack.includes?(name)
      end

      T::Sig::WithoutRuntime.sig {
        params(block: T.nilable(T.proc.void)).returns(Kuby::Docker::Credentials)
      }
      def credentials(&block)
        @credentials ||= Credentials.new
        @credentials.instance_eval(&block) if block
        @credentials
      end

      T::Sig::WithoutRuntime.sig { void }
      def after_configuration
        @image = begin
          dockerfile = Dockerfile.new.tap do |df|
            layer_stack.each { |layer| layer.apply_to(df) }
          end

          Docker::AppImage.new(
            dockerfile, T.must(image_url_str), credentials, registry_index_url_str
          )
        end
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::SetupPhase) }
      def setup_phase
        @setup_phase ||= SetupPhase.new(environment, self)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::PackagePhase) }
      def package_phase
        @package_phase ||= PackagePhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::BundlerPhase) }
      def bundler_phase
        @bundler_phase ||= BundlerPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::YarnPhase) }
      def yarn_phase
        @yarn_phase ||= YarnPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::CopyPhase) }
      def copy_phase
        @copy_phase ||= CopyPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::AppPhase) }
      def app_phase
        @app_phase ||= AppPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::AssetsPhase) }
      def assets_phase
        @assets_phase ||= AssetsPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::WebserverPhase) }
      def webserver_phase
        @webserver_phase ||= WebserverPhase.new(environment)
      end

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::Distro) }
      def distro_spec
        @distro_spec ||= if distro_klass = Kuby.distros[distro_name]
          distro_klass.new(self)
        else
          raise MissingDistroError, "distro '#{distro_name}' hasn't been registered"
        end
      end

      private

      T::Sig::WithoutRuntime.sig { returns(Kuby::Docker::LayerStack) }
      def layer_stack
        @layer_stack ||= Kuby::Docker::LayerStack.new.tap do |stack|
          stack.use(:setup_phase, setup_phase)
          stack.use(:package_phase, package_phase)
          stack.use(:bundler_phase, bundler_phase)
          stack.use(:yarn_phase, yarn_phase)
          stack.use(:copy_phase, copy_phase)
          stack.use(:app_phase, app_phase)
          stack.use(:assets_phase, assets_phase)
          stack.use(:webserver_phase, webserver_phase)
        end
      end
    end
  end
end
