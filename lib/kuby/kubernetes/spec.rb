require 'kube-dsl'

module Kuby
  module Kubernetes
    class Spec
      extend ::KubeDSL::ValueFields

      attr_reader :definition, :plugins

      def initialize(definition)
        @definition = definition
        @plugins = TrailingHash.new

        # default plugins
        add_plugin(:rails_app)
      end

      def provider(provider_name = nil, &block)
        if provider_name
          if @provider || provider_klass = Kuby.providers[provider_name]
            @provider ||= provider_klass.new(definition)
            @provider.configure(&block)
          else
            msg = if provider_name
              "no provider registered with name #{provider_name}, "\
                'do you need to add a gem to your Gemfile?'
            else
              'no provider configured'
            end

            raise MissingProviderError, msg
          end
        end

        @provider
      end

      def configure_plugin(plugin_name, &block)
        if @plugins[plugin_name] || plugin_klass = Kuby.plugins[plugin_name]
          @plugins[plugin_name] ||= plugin_klass.new(definition)
          @plugins[plugin_name].configure(&block) if block
        else
          raise MissingPluginError, "no plugin registered with name #{plugin_name}, "\
            'do you need to add a gem to your Gemfile?'
        end
      end

      alias_method :add_plugin, :configure_plugin

      def plugin(plugin_name)
        @plugins[plugin_name]
      end

      def after_configuration
        @plugins.each { |_, plg| plg.after_configuration }
        provider.after_configuration
      end

      def setup
        provider.before_setup
        provider.setup

        @plugins.each { |_, plg| plg.before_setup }
        @plugins.each { |_, plg| plg.setup }
        @plugins.each { |_, plg| plg.after_setup }

        provider.after_setup
      end

      def deploy(tag = nil)
        tag ||= latest_tag

        unless tag
          raise Kuby::Docker::MissingTagError, 'could not find latest timestamped tag'
        end

        set_tag(tag)

        provider.before_deploy(resources)
        @plugins.each { |_, plg| plg.before_deploy(resources) }

        provider.deploy

        @plugins.each { |_, plg| plg.after_deploy(resources) }
        provider.after_deploy(resources)
      end

      def rollback
        depl = provider.kubernetes_cli.get_object(
          'deployment', namespace.metadata.name, deployment.metadata.name
        )

        image_url = depl.dig('spec', 'template', 'spec', 'containers', 0, 'image')

        unless image_url
          raise MissingDeploymentError, "couldn't find an existing deployment"
        end

        deployed_tag = ::Kuby::Docker::TimestampTag.try_parse(image_url.split(':').last)
        all_tags = docker.tags.all.timestamp_tags.sort
        tag_idx = all_tags.index { |tag| tag.time == deployed_tag.time } || 0

        if tag_idx == 0
          raise Kuby::Docker::MissingTagError, 'could not find previous tag'
        end

        previous_tag = all_tags[tag_idx - 1]
        deploy(previous_tag.to_s)
      end

      def namespace(&block)
        spec = self

        @namespace ||= KubeDSL.namespace do
          metadata do
            name "#{spec.selector_app}-#{spec.definition.environment}"
          end
        end

        @namespace.instance_eval(&block) if block
        @namespace
      end

      def resources
        @resources ||= Manifest.new([
          namespace,
          *@plugins.flat_map { |_, plugin| plugin.resources }
        ])
      end

      def set_tag(tag)
        plugin(:rails_app).set_image("#{docker.metadata.image_url}:#{tag}")
      end

      def selector_app
        @selector_app ||= definition.app_name.downcase
      end

      def docker
        definition.docker
      end

      private

      def latest_tag
        @latest_tag ||= docker.tags.local.latest_tags.find do |tag|
          tag != ::Kuby::Docker::Tags::LATEST
        end
      end
    end
  end
end
