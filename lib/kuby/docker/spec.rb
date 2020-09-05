require 'docker/remote'

module Kuby
  module Docker
    class Spec
      attr_reader :environment

      def initialize(environment)
        @environment = environment
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
        @distro_spec = nil
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

      def use(*args, &block)
        layer_stack.use(*args, &block)
      end

      def insert(*args, &block)
        layer_stack.insert(*args, &block)
      end

      def delete(*args)
        layer_stack.delete(*args)
      end

      def exists?(*args)
        layer_stack.includes?(*args)
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
        @setup_phase ||= SetupPhase.new(environment)
      end

      def package_phase
        @package_phase ||= PackagePhase.new(environment)
      end

      def bundler_phase
        @bundler_phase ||= BundlerPhase.new(environment)
      end

      def yarn_phase
        @yarn_phase ||= YarnPhase.new(environment)
      end

      def copy_phase
        @copy_phase ||= CopyPhase.new(environment)
      end

      def assets_phase
        @assets_phase ||= AssetsPhase.new(environment)
      end

      def webserver_phase
        @webserver_phase ||= WebserverPhase.new(environment)
      end

      def metadata
        @metadata ||= Metadata.new(environment)
      end

      def tag
        t = ENV.fetch('KUBY_DOCKER_TAG') do
          tags.latest_timestamp_tag
        end

        unless t
          raise MissingTagError, 'could not find latest timestamped tag'
        end

        t.to_s
      end

      def previous_tag(current_tag)
        t = tags.previous_timestamp_tag(current_tag)

        unless t
          raise MissingTagError, 'could not find previous timestamped tag'
        end

        t.to_s
      end

      def cli
        @cli ||= Docker::CLI.new
      end

      def remote_client
        @remote_client ||= ::Docker::Remote::Client.new(
          metadata.image_host, metadata.image_repo,
          credentials.username, credentials.password,
        )
      end

      def distro_spec
        @distro_spec ||= if distro_klass = Kuby.distros[metadata.distro]
          distro_klass.new(self)
        else
          raise MissingDistroError, "distro '#{metadata.distro}' hasn't been registered"
        end
      end

      def tags
        @tags ||= Tags.new(cli, remote_client, metadata)
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
