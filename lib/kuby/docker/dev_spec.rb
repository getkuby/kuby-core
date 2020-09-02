module Kuby
  module Docker
    class WebserverDevPhase < Layer
      DEFAULT_PORT = 3000

      attr_accessor :port

      def apply_to(dockerfile)
        # do nothing
      end

      def port
        @port || DEFAULT_PORT
      end
    end

    class DevSpec
      attr_reader :environment

      def initialize(environment)
        @environment = environment
      end

      def working_dir(dir)
        setup_phase.working_dir = dir
      end

      def rails_env(env)
        setup_phase.rails_env = env
      end

      def package(pkg)
        package_phase << pkg
      end

      def distro(distro_name)
        metadata.distro = distro_name
        @distro_spec = nil
      end

      def port(port)
        webserver_phase.port = port
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

      def to_dockerfile
        Dockerfile.new.tap do |df|
          layer_stack.each { |layer| layer.apply_to(df) }
          df.cmd("#{distro_spec.shell_exe} -c 'while test 1; do sleep 5; done'")
        end
      end

      def setup_phase
        @setup_phase ||= SetupPhase.new(environment)
      end

      def package_phase
        @package_phase ||= PackagePhase.new(environment)
      end

      def webserver_phase
        @webserver_phase ||= WebserverDevPhase.new(environment)
      end

      def metadata
        @metadata ||= Metadata.new(environment)
      end

      def cli
        @cli ||= Docker::CLI.new
      end

      def distro_spec
        @distro_spec ||= if distro_klass = Kuby.distros[metadata.distro]
          distro_klass.new(self)
        else
          raise MissingDistroError, "distro '#{metadata.distro}' hasn't been registered"
        end
      end

      private

      def layer_stack
        @layer_stack ||= LayerStack.new.tap do |stack|
          stack.use(:setup_phase, setup_phase)
          stack.use(:package_phase, package_phase)
          stack.use(:webserver_phase, webserver_phase)
        end
      end
    end
  end
end
