# typed: false
require 'kube-dsl'
require 'rake'

module Kuby
  module Kubernetes
    class Spec
      extend ::KubeDSL::ValueFields

      attr_reader :environment, :plugins, :tag

      def initialize(environment)
        @environment = environment
        @plugins = TrailingHash.new

        # default plugins
        add_plugin(:system)
        add_plugin(:rails_app)
      end

      def provider(provider_name = nil, &block)
        if provider_name
          provider_klass = Kuby.providers[provider_name]

          unless provider_klass
            begin
              # attempt to auto-require
              require "kuby/#{provider_name}"
              provider_klass = Kuby.providers[provider_name]
            rescue LoadError
            end
          end

          if provider_klass
            if !@provider || !@provider.is_a?(provider_klass)
              @provider = provider_klass.new(environment)
            end

            @provider.configure(&block)
          else
            msg = if provider_name
              "no provider registered with name #{provider_name}, "\
                'do you need to add a gem to your Gemfile and/or a '\
                'require statement to your Kuby config?'
            else
              'no provider configured'
            end

            raise MissingProviderError, msg
          end
        end

        @provider
      end

      def configure_plugin(plugin_name, &block)
        unless @plugins.include?(plugin_name)
          plugin_klass = Kuby.plugins.find(plugin_name)
          @plugins[plugin_name] = plugin_klass.new(environment)
        end

        @plugins[plugin_name].configure(&block) if block
      end

      alias_method :add_plugin, :configure_plugin

      def plugin(plugin_name)
        @plugins[plugin_name]
      end

      def after_configuration
        @plugins.each { |_, plg| plg.after_configuration }
        provider.after_configuration
        environment.docker.after_configuration

        spec = self

        # this must be done _after_ docker has been configured
        registry_secret do
          docker_config do
            registry_host spec.docker.image.image_hostname
            username spec.docker.image.credentials.username
            password spec.docker.image.credentials.password
            email spec.docker.image.credentials.email
          end
        end
      end

      def before_deploy
        @tag ||= docker.image.current_version.main_tag

        check_dependencies!

        provider.before_deploy(resources)
        @plugins.each { |_, plg| plg.before_deploy(resources) }
      ensure
        @tag = nil
      end

      def check_dependencies!(plugins = @plugins)
        error_messages = []

        plugins.each do |plg_name, plg|
          plg.class.dependencies.each do |dependency|
            dependable = Kuby.dependables[dependency.name]

            unless dependable
              error_messages << "The #{plg_name} plugin depends on #{dependency.name}, "\
                "but that dependency has not been registered."

              next
            end

            unless dependency.satisfied_by?(dependable)
              error_messages << "The #{plg_name} plugin depends on #{dependency.name} "\
                "#{dependency.constraints}, but the available version is #{dependable.version}."
            end
          end
        end

        unless error_messages.empty?
          error_messages.each { |msg| Kuby.logger.fatal(msg) }
          exit 1
        end
      end

      def after_deploy
        @tag ||= docker.image.current_version.main_tag

        @plugins.each { |_, plg| plg.after_deploy(resources) }
        provider.after_deploy(resources)
      ensure
        @tag = nil
      end

      def setup(only: [])
        plugins = if only.empty?
          @plugins
        else
          @plugins.each_with_object({}) do |(name, plg), memo|
            memo[name] = plg if only.include?(name)
          end
        end

        check_dependencies!(plugins)

        if only.empty?
          provider.before_setup
          provider.setup
        end

        plugins.each { |_, plg| plg.before_setup }
        plugins.each { |_, plg| plg.setup }
        plugins.each { |_, plg| plg.after_setup }

        provider.after_setup
      end

      def deploy(tag = nil)
        @tag = tag

        before_deploy
        provider.deploy
        after_deploy
      end

      def rollback
        # it sucks that we have to reach into the rails app for this...
        depl = provider.kubernetes_cli.get_object(
          'deployment',
          namespace.metadata.name,
          plugin(:rails_app).deployment.metadata.name
        )

        image_url = depl.dig('spec', 'template', 'spec', 'containers', 0, 'image')

        unless image_url
          raise MissingDeploymentError, "couldn't find an existing deployment"
        end

        deployed_tag = image_url.split(':').last
        previous_tag = docker.metadata.previous_tag(deployed_tag)

        deploy(previous_tag)
      end

      def namespace(&block)
        spec = self

        @namespace ||= KubeDSL.namespace do
          metadata do
            name "#{spec.selector_app}-#{spec.environment.name}"
          end
        end

        @namespace.instance_eval(&block) if block
        @namespace
      end

      def registry_secret(&block)
        spec = self

        @registry_secret ||= RegistrySecret.new do
          metadata do
            name "#{spec.selector_app}-registry-secret"
            namespace spec.namespace.metadata.name
          end
        end

        @registry_secret.instance_eval(&block) if block
        @registry_secret
      end

      def resources
        @resources ||= Manifest.new([
          namespace,
          registry_secret,
          *@plugins.flat_map { |_, plugin| plugin.resources }
        ].compact)
      end

      def docker_images
        @docker_images ||= [
          docker.image, *@plugins.flat_map { |_, plugin| plugin.docker_images }
        ]
      end

      def selector_app
        @selector_app ||= environment.app_name.downcase
      end

      def docker
        environment.docker
      end
    end
  end
end
