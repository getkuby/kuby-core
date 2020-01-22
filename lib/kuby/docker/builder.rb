module Kuby
  module Docker
    class Builder
      class << self
        def build(app, &block)
          new(app, &block)
        end
      end

      attr_reader :app

      def initialize(app, &block)
        @app = app
        instance_eval(&block) if block
      end

      def base_image(image_url)
        setup_phase.base_image = image_url
      end

      def working_dir(dir)
        setup_phase.working_dir = dir
      end

      def rails_env(env)
        setup_phase.rails_env = env
      end

      def bundler_version(version)
        bundler_phase.bundler_version = version
      end

      def gemfile(path)
        bundler_phase.gemfile = path
      end

      def package(pkg)
        package_phase << pkg
      end

      def files(path)
        copy_phase << path
      end

      def port(port)
        webserver_phase.port = port
      end

      def use(*args)
        layer_stack.use(*args)
      end

      def insert(*args)
        layer_stack.insert(*args)
      end

      def delete(*args)
        layer_stack.delete(*args)
      end

      def to_dockerfile
        Dockerfile.new.tap do |df|
          layer_stack.each { |layer| layer.apply_to(df) }
        end
      end

      def setup_phase
        @setup_phase ||= SetupPhase.new(app)
      end

      def package_phase
        @package_phase ||= PackagePhase.new(app)
      end

      def bundler_phase
        @bundler_phase ||= BundlerPhase.new(app)
      end

      def yarn_phase
        @yarn_phase ||= YarnPhase.new(app)
      end

      def copy_phase
        @copy_phase ||= CopyPhase.new(app)
      end

      def assets_phase
        @assets_phase ||= AssetsPhase.new(app)
      end

      def webserver_phase
        @webserver_phase ||= WebserverPhase.new(app)
      end

      private

      def layer_stack
        @layer_stack ||= LayerStack.new.tap do |stack|
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
