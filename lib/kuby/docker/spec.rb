module Kuby
  module Docker
    class MissingTagError < StandardError
      attr_reader :tag

      def initialize(tag)
        @tag = tag
      end

      def message
        @message ||= "Could not find tag '#{tag}'."
      end
    end

    class Spec
      attr_reader :definition

      def initialize(definition)
        @definition = definition
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

      def distro(distro_name)
        metadata.distro = distro_name
        package_phase.distro_updated
      end

      def files(path)
        copy_phase << path
      end

      def port(port)
        webserver_phase.port = port
      end

      def image_url(url)
        metadata.image_url = url
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

      def credentials(&block)
        @credentials ||= Credentials.new
        @credentials.instance_eval(&block) if block
        @credentials
      end

      def to_dockerfile
        Dockerfile.new.tap do |df|
          layer_stack.each { |layer| layer.apply_to(df) }
        end
      end

      def setup_phase
        @setup_phase ||= SetupPhase.new(definition)
      end

      def package_phase
        @package_phase ||= PackagePhase.new(definition)
      end

      def bundler_phase
        @bundler_phase ||= BundlerPhase.new(definition)
      end

      def yarn_phase
        @yarn_phase ||= YarnPhase.new(definition)
      end

      def copy_phase
        @copy_phase ||= CopyPhase.new(definition)
      end

      def assets_phase
        @assets_phase ||= AssetsPhase.new(definition)
      end

      def webserver_phase
        @webserver_phase ||= WebserverPhase.new(definition)
      end

      def metadata
        @metadata ||= Metadata.new(definition)
      end

      def latest_tags
        # find latest tag
        images = Kuby.docker_cli.images(metadata.image_url)
        latest = images.find { |image| image[:tag] == 'latest' }

        unless latest
          raise MissingTagError.new('latest')
        end

        # find all tags that point to the same image as 'latest'
        # and push them up
        images.each_with_object([]) do |image_data, tags|
          if image_data[:id] == latest[:id]
            tags << image_data[:tag]
          end
        end
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
